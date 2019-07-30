
# Cmd to Run


#  1. Docker commands

+ docker build -t gbausier/dummyopentargetdatav3 .
+ docker run -d -p 8004:8004 gbausier/dummyopentargetdatav3


#  2. URL testing

+ OPEN CPU web interface : http://localhost:8004/ocpu/test/ 
+ Path to use in the web interface ../library/dummyOpenTargetData/R/getDummyData


#  3. CURL commands

curl -k -H "Content-Type: application/json" -X POST -d '{"n": 50}' http://localhost:8004/ocpu/library/dummyOpenTargetData/R/getHighestScore/json

curl -k -H "Content-Type: application/json" -X POST -d '{"rsid": "rs3825937"}' http://localhost:8004/ocpu/library/dummyOpenTargetData/R/getRsidDummyData/json

curl -k -H "Content-Type: application/json" -X POST -d '{"rsid": "rs140463209"}' http://localhost:8004/ocpu/library/dummyOpenTargetData/R/getPhenoScannerData/json 
