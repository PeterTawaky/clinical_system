# Examinations Feature 
create a top navigation bar with four tabs: 
1. حجز الكشوفات 
2. الكشوفات المؤقتة 
3. الكشوفات المؤكدة
4. الكشوفات الملغية

## Tasks to work on:
حجز الكشوفات  for feature
#### Facilities
##### Filter
- can filter by day , Specialty, branch through drop down menus days all week days , Specialty all specialties in the HTTP request below
get all branches available through HTTP request below if there is no branch allow an option or button to add a new branch first you can open a dialog wrapped with BackdropFilter to put blur for the background

##### Search bar
- Search by doctor name

#### Main Functions
##### View doctor_schedules through the http get request with endpoint: get all doctors
- entity we need to view in screen: 
    "اسم الدكتور": "",
    "التخصص": "",
    الأيام ووقت البدء والأنتهاء
    branches


- we need to add button to when click on it open a alert dialog wrapped with BackdropFilter to put blur for the background and generate an examination and take the needed data
when try to add the patient make request to get all patients while writing the name and if found and the user clicked it automatically enter all it's data on the screen if not in the patients list make an option to add new patient and take the needed data related to patient and save it in the database and then use it to generate the examination

- after entering all the needed data related to the examination save it in the database and show a success message to the user and then return to the examinations view. for the column status of table  examination put it's value to be مؤقت

show all this data in the shape of tables



حجز الكشوفات  for feature
- view all current examinations with it's status مؤقت
put search by user name(search bar) and filteration by date make it by deafult today
UI:
    - service name
    - price
    - patient name
    - doctor name
    - patient phone number
    - examination status
and for each row make a button for cancel the examination: endpoint
and another button for confirm the examination: endpoint


الكشوفات المؤكدة  for feature
- view all current examinations with it's status مؤكد
put search by user name(search bar) and filteration by date make it by deafult today
UI:
    - service name
    - price
    - patient name
    - doctor name
    - patient phone number
    - examination status


الكشوفات الملغية  for feature
- view all current examinations with it's status ملغى
put search by user name(search bar) and filteration by date make it by deafult today
UI:
    - service name
    - price
    - patient name
    - doctor name
    - patient phone number
    - examination status

### NOTE: you can see all server apis in this file: server_simulate.md