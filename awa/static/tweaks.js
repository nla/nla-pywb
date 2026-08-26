document.addEventListener("DOMContentLoaded", function() {
    // disable mailto: links
    var links = document.querySelectorAll("a[href^='mailto:']");
    for (var i = 0; i < links.length; ++i) {
        links[i].onclick = function(){ alert('Email links are disabled in the web archive'); return false; }
        links[i].href = 'javascript:void(0)';
    }
    // disable password fields
    var fields = document.querySelectorAll("input[type='password']");
    for (var i = 0; i < fields.length; ++i) {
        fields[i].disabled = true;
        fields[i].title = 'Password fields are disabled in the web archive';
    }

    // replace real media and quicktime embeds with a video tag for the transcoding service
    for (const embed of document.querySelectorAll('embed[src*=".rm"], embed[src*=".mov"]')) {
        const video = document.createElement('video');
        video.preload = 'none';
        video.src = wbinfo.static_prefix + "transcode?date=" + wbinfo.timestamp + "&url=" + encodeURIComponent(embed.src);
        video.controls = true;
        video.width = embed.width;
        video.height = embed.height;
        embed.parentNode.replaceChild(video, embed);
    }

    // replace old flash video player with a HTML5 video tag
    // eg https://webarchive.nla.gov.au/awa/20131211003215/http://pandora.nla.gov.au/pan/120423/20131210-0041/www.youtube.com/watch78bd.html
    //    http://pandora.nla.gov.au/pan/145179/20140403-1226/HazelwoodCFA2.html
    for (const embed of document.querySelectorAll('embed[src*="player.swf"][flashvars*="file="]')) {
        const flashvars = Object.fromEntries(embed.attributes['flashvars'].value.split('&').map(s => s.split('=', 2)));
        let file = flashvars['file'];
        let src;
        if (file.endsWith(".mp4")) {
            src = file;
        } else if (file.endsWith(".flv")) {
            let flvUrl = new URL(file, document.location).toString().substring(wbinfo.prefix.length +
                wbinfo.request_ts.length + wbinfo.mod.length + 1)
            src = wbinfo.static_prefix + "transcode?date=" + wbinfo.timestamp + "&url=" + encodeURIComponent(flvUrl);
        } else {
            continue;
        }
        const video = document.createElement('video');
        video.preload = 'none';
        video.src = src;
        video.width = flashvars['width'];
        video.height = flashvars['height'];
        if (flashvars['image']) video.poster = flashvars['image'];
        video.controls = true;
        embed.parentNode.replaceChild(video, embed);
    }
});

// Site-specific workarounds:

// https://webarchive.nla.gov.au/awa/20001004130000/http://www.unolympics.com/index.html
if (wbinfo.url.startsWith("http://www.unolympics.com/")) {
    document.layers = true; // trick version detection into thinking we're Netscape 4
}
// https://webarchive.nla.gov.au/awa/20170802002621/http://pandora.nla.gov.au/pan/14247/20170802-0307/www.gymnastics.org.au/index.html
// https://webarchive.nla.gov.au/awa/20241007234200/http://pandora.nla.gov.au/pan/212754/20241008-1042/www.asuvictas.com.au/VICTAS/Campaigns/Victorian_Local_Council_Elections.aspx
document.cookie = "Asi.Web.Browser.CookiesEnabled=true;path=/;SameSite=None;Secure"; // trick cookie detection logic

// https://webarchive.nla.gov.au/awa/20001213070000/http://olympics.com.au/PhotoGallery/0,1140,,00.html
if (wbinfo.url.startsWith("http://olympics.com.au/")) {
    // disable broken redirect to frameset
    document.addEventListener("DOMContentLoaded", function () {
        window.check_frame = function () {};
    });
}

window.RufflePlayer.config.autoplay = "on";
window.RufflePlayer.config.unmuteOverlay = "hidden";
