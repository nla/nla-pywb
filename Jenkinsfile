def isMaster = env.BRANCH_NAME == 'master'
def isTag = env.TAG_NAME || env.BRANCH_NAME ==~ /^tags\/.+/

def develApps = ['pandas-pywb-public', 'pandas-pywb-qa']

properties([
    disableConcurrentBuilds(abortPrevious: true)
])

node('spade') {
    stage('Build OCI image') {
        checkout scm

        def sourceCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
        def imageVersion
        if (isTag) {
            imageVersion = env.TAG_NAME ?: env.BRANCH_NAME.substring('tags/'.length())
        } else if (isMaster) {
            imageVersion = "master-${sourceCommit}"
        } else {
            imageVersion = "build-${sourceCommit}"
        }

        withEnv([
            'CONTAINER_REGISTRY=container-registry.prod.nla.gov.au',
            "IMAGE_VERSION=${imageVersion}",
            'NO_PROXY=localhost,127.0.0.1,.nla.gov.au',
            'no_proxy=localhost,127.0.0.1,.nla.gov.au'
        ]) {
            sh '''
                set -eu

                podman build \
                    --platform linux/amd64 \
                    --file Dockerfile \
                    --tag "$CONTAINER_REGISTRY/nla/pywb:$IMAGE_VERSION" \
                    .
            '''

            if (isMaster || isTag) {
                stage('Push OCI image') {
                    withCredentials([usernamePassword(
                        credentialsId: 'harbor-pandas-pusher',
                        usernameVariable: 'HARBOR_USERNAME',
                        passwordVariable: 'HARBOR_PASSWORD'
                    )]) {
                        sh '''
                            set +x
                            printf '%s' "$HARBOR_PASSWORD" | podman login \
                                --username "$HARBOR_USERNAME" \
                                --password-stdin \
                                "$CONTAINER_REGISTRY"
                        '''

                        try {
                            retry(3) {
                                sh '''podman push "$CONTAINER_REGISTRY/nla/pywb:$IMAGE_VERSION"'''
                            }
                        } finally {
                            sh '''podman logout "$CONTAINER_REGISTRY" || true'''
                        }
                    }
                }
            }
        }
    }

    if (isMaster) {
        stage('Deploy pywb to devel') {
            def sourceCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
            def imageVersion = "master-${sourceCommit}"
            def valuesFiles = develApps.collect { ".gitops/${it}/devel/values.yaml" }.join(' ')

            dir('argocd-deploy') {
                deleteDir()

                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/talos']],
                    userRemoteConfigs: [[
                        credentialsId: 'argocd-gitlab-writer',
                        url: 'git@gitlab.nla.gov.au:nla/argocd.git'
                    ]]
                ])

                withEnv(["IMAGE_VERSION=${imageVersion}", "VALUES_FILES=${valuesFiles}"]) {
                    sh '''
                        set -eu

                        for f in $VALUES_FILES; do
                            sed -i -E "s/^version: .*/version: ${IMAGE_VERSION}/" "$f"
                            test "$(sed -n 's/^version: //p' "$f")" = "$IMAGE_VERSION"
                        done

                        git diff --check

                        if git diff --quiet -- $VALUES_FILES; then
                            echo "pywb devel already references ${IMAGE_VERSION}"
                            exit 0
                        fi

                        git config user.name 'pandas-ui deployment bot'
                        git config user.email 'pandas-ui-deploy@nla.gov.au'
                        git add $VALUES_FILES
                        git commit -m "pywb/devel: deploy ${IMAGE_VERSION}"
                    '''

                    sshagent(credentials: ['argocd-gitlab-writer']) {
                        sh '''
                            set -eu
                            git fetch origin talos
                            if ! git rebase origin/talos; then
                                git rebase --abort || true
                                exit 1
                            fi
                            git push origin HEAD:talos
                        '''
                    }
                }
            }
        }
    }
}
