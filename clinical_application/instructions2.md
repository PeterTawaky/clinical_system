generate a new feature الماليات in the navigation bar
create a top navigation bar with four tabs:

1. المشتريات
2. الفواتير
3. الديون
4. الخزنة

for المشتريات:

- main screen containing all purchases and no.of items for each purchase through the request get purchases
  a small statistics show total price of all purchases and total price of paid purchases and total price of unpaid purchases and a number of purchases
  filter by branch_id get all branches from endpoint
  filter by user name from endpoint
  filter by date
  filter by status (مديونية, تم السداد) make it's default value in the ui is مديونية

- a small icon for each purchase to edit purchase data and any purchase line
- a small icon to delete purchase
- a small button to pay purchase
  a button to add a new purchase with all the needed data (generate a new purchase request) open a alert dialog wrapped with BackdropFilter to put blur for the background to add a new purchase with all the needed data
- when click on any purchase show all the items in the purchase line

for الفواتير:

- main screen containing all invoices and no.of items for each invoice through the request get invoices
  a small statistics show total price of all invoices and total price of paid invoices and total price of unpaid invoices and a number of invoices
  filter by branch_id get all branches from endpoint
  filter by user name from endpoint
  filter by date
  filter by status (مديونية, تم السداد) make it's default value in the ui is مديونية

- a small icon for each invoice to edit invoice data
- a small icon to delete invoice
- a small icon to pay invoice
  a button to add a new invoice with all the needed data (generate a new invoice request) open a alert dialog wrapped with BackdropFilter to put blur for the background to add a new invoice with all the needed data

for الديون:

- main screen containing all debts and no.of items for each debt through the request get debts
  a small statistics show total price of all debts and total price of paid debts and total price of unpaid debts and a number of debts
  filter by branch_id get all branches from endpoint
  filter by user name from endpoint
  filter by created date
  filter by payment date
  filter by status (مديونية, تم السداد) make it's default value in the ui is مديونية

- a small icon for each debt to edit debt data
- a small icon to delete debt
- a small button to pay a debt

for الخزنة:

- main screen containing all cash_boxes and no.of items for each cash_box through the request get cash_boxes
  a small statistics show total income, total expense , balance and no. of transactions you can found all those data in the endpoints
- a small icon for each cash_box to edit cash_box data
- a small icon to delete cash_box
  filters available for this:
  created_date
  transaction_type
  username:
  branch_id:
