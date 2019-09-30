import requests
import json
from datetime import date
from defectdojo_api import defectdojo

# setup DefectDojo connection information
host = 'http://127.0.0.1:8080/'
api_key = 'YOUR API KEY'
user = 'admin'

#CX url
cx_url = 'YOUR CHECKMARX ENDPOINT'

#Checkmarx Info
r_data = {'username':'CHECKMARX USER',
        'password':'PASSWORD',
        'grant_type':'password',
        'scope': 'sast_rest_api',
          'client_id': 'resource_owner_client',
          'client_secret': 'CLIENT SECRET'
          }

# gets CX auth header
r = requests.post(cx_url + '/cxrestapi/auth/identity/connect/token', r_data, verify=False,)
access_token = json.loads(r.text)['access_token']
headers = {"Authorization": "Bearer %s" % access_token, "Accept":
    "application/json"}

# instantiate the DefectDojo api wrapper
dd = defectdojo.DefectDojoAPI(host, api_key, user, debug=False, verify_ssl=False)

# gets dojo products in json
json_prods = json.loads(dd.list_products().data_json())

# loops until product pagination is less than 20 python does not have do/while
# so while(true) is neccesary

while(True):
    # loops through first page of products
    for product in json_prods['objects']:
        # gets product id
        p_id = product['id']
        # checks if CX confg is available value should be updated based on instance
        #tool_config_id
        dd_tools = dd.list_tool_products(product_id=p_id, tool_configuration_id=1)
        #checking if CX configuration is found
        if dd_tools.count() == 1:
            print ("PROCEEDING: One configuration found")
            # checks to see if a continuous engagement already exists
            c_engagement = dd.list_engagements(product=p_id, name_contains="Continuous Checkmarx Engagement").data_json(pretty=True)
            if len(json.loads(c_engagement)['objects']) == 0:
                print ("PROCEEDING: No engagement found, creating")
                c_engagement = dd.create_engagement(name="Continuous Checkmarx Engagement")
            else:
                print ("PROCEEDING: Engagement found, using what exists.")
                c_engagement = json.loads(c_engagement)['objects'][0]
            # grabbing continous test, if it exists
            c_test = dd.list_tests(engagement=c_engagement['id'], title='Continuous Checkmarx Engagement').data_json()
            json_tools = json.loads(dd_tools.data_json())
            #getting neccesary information to construct CX urls
            proj_id = json_tools['objects'][0]['tool_project_id']
            r_url = cx_url + '/cxrestapi/sast/scans?last=1&projectId='+ str(proj_id)
            r_get_recent_scan = requests.get(r_url,
                headers=headers, verify=False)
            recent_scan_id = json.loads(r_get_recent_scan.text)[0]['id']
            data = {
                "reportType": "XML",
                "scanId": recent_scan_id
            }
            #creates CX report
            r_create_report = requests.post(
                cx_url + '/cxrestapi/reports/sastScan',
                headers=headers, verify=False, data=data)
            report_id = json.loads(r_create_report.text)['reportId']
            report_url = cx_url + '/cxrestapi/reports/sastScan/' + str(report_id)
            report_status = 'Not Started'
            #waits for the report to be ready
            while(report_status != 'Created'):
                status_url = cx_url + '/cxrestapi/reports/sastScan/'+ str(report_id) + '/status'
                report_status_request = requests.get(status_url, headers=headers, verify=False)
                report_status = json.loads(report_status_request.text)['status']['value']
            #gets the CX report
            get_report = requests.get(report_url, headers=headers, verify=False)
            scan_file =  open('report.xml', 'w')
            scan_file.write(get_report.text)
            scan_file.close()
            #checks to decide if we should upload or reupload
            if json.loads(c_test)['meta']['total_count'] == 0:
                dd.upload_scan(engagement_id=c_engagement['id'], scan_type='Checkmarx', file='report.xml', active=True, scan_date='01/01/2019', minimum_severity="High")
                print ("Upload complete")
            else:
                dd.reupload_scan(engagement_id=c_engagement['id'], scan_type='Checkmarx', file='report.xml', scan_date='01/01/2019',minimum_severity="High")
                print ("Reupload complete")
        elif dd_tools.count() > 1:
            print ("ERROR too many configurations for product id %d" % p_id)
        else:
            print ("ERROR configuration missing for product id %d" % p_id)
    if len(json_prods) < 20:
        break
    json_prods = json.loads(dd.list_products().data_json())

