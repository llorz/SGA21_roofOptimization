var ttt1 = new Date().getTime()

self.addEventListener('message', function(e) {
    // console.log(e)
    if (e.data === 'start') {
        setInterval(function() {
            getData()


        }, 100);
    }

    function getData() {

        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'http://10.151.190.26:5010/vehicle/data');
        // xhr.withCredentials = true;
        // xhr.setRequestHeader("Content-Type", "text/event-stream");
        xhr.onreadystatechange = function() {
            // let json1 = JSON.parse(xhr.responseText)
            if (xhr.readyState === 4) {
                // console.log(xhr.responseText)
                let ttt2 = new Date().getTime()
                console.log(ttt2 - ttt1)
                ttt1 = ttt2
            }
        }
        xhr.send();


    }

});