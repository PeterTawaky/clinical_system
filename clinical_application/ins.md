### Setting Feature (on the Drawer carries other sub features)
create a top navigation bar with sub Features tabs: 

#### 1. Doctors Feature (sub feature)
- the main screen is to view all doctors through get all doctors api request
for each row in the table view we need to show: 
    - doctor name
    - specialty
    - phone number
    - balance
    - branches
    - doctor schedules 
    - doctor services and price
    - a small icon for each doctor to edit docotrs data, add a new schedule, add a new service, delete a schedule, delete a service and etc..
    - a small icon to delete a doctor
a button to add a new doctor with all the needed data (generate a new doctor request)
open a alert dialog wrapped with BackdropFilter to put blur for the background to add a new doctor with all the needed data
special shape for some fields:
    - branches (drop down menu) from request get branches
    - doctor schedules (drop down menu for week days) and a good shape for clock start and end.
    - balance is an optional to add but put it by deafult equals zero.



#### 2. Branches Feature
- main screen containing all branches and no.of doctors for each branch through the request get branches 
- a small icon for each branch to edit branch data
- a small icon to delete a branch
a button to add a new branch with all the needed data (generate a new branch request) open a alert dialog wrapped with BackdropFilter to put blur for the background to add a new branch with all the needed data
