function sendLink(){
    var URL = $request.url;
    var dest = new Object();
    dest.url = "http://127.0.0.1:16300";
    dest.headers = {
        "Content-Type": "application/json"
    };
    dest.body = {
        "LINK": URL
    };
    $httpClient.post(dest);
};
sendLink();
$done({});