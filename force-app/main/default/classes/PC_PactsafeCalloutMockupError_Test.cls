@IsTest
global class PC_PactsafeCalloutMockupError_Test implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        //System.assertEquals('http://pactsafe.com/example/test', req.getEndpoint()); //EXCL-6
        System.assertEquals('GET', req.getMethod());
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"page_query":"groupType=Master-Reseller&partnerType=Reseller&email=pavanaja@accenture.com","download_url":"https://public.pactsafe.com/v1.1/download/activity/5c4ff210647c037683283650?expires=0&signature=PbVp~tkczVg4jl4AQ9OQ7SUi6wFMCKcqtpAYJoY3GqtMus5ICe0fn4eRMH~L4TelpOTHGfYZA6o9LaPt8w3qOrOUdzwp8Og~nRn8ioJGfnyFo4PHHDursUpC0wXoJKSdt6es~W7C4Pa5o~HNKsoDzZYykJBf7-vsfrhITssmLsGfGm6TPPjT6ucb76sPT5Ni0pAYGmrMNpk8qyLSAFVLvGvubd-E4lwrm5LotGuW~tqHkPwbJQrZUI-0pDgwNUTk3BMkhASkZC~cNWV~OqxcqAwyYLFd~2ed4LU4mWxYYqRjWFR18YfZYF8IN-C5aIhMjfVemlgCqTAEYasVSoPPzw__","id":"5c4ff210647c037683283650"}');
        res.setStatusCode(400);
        res.setStatus('FAIL');
        return res;
    }
}