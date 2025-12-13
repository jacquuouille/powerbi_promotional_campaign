# Power BI Project: Promotional Campaign Analysis Dashboard

## Overview 
Proviving a comprehensive view of behaviours of a coffee shop members over a 30-day period, including their transactions and responses to promotional offers.

👉 [Power BI Dashboard](https://app.powerbi.com/view?r=eyJrIjoiZDlmNzM2NDAtMjkxMC00NzdjLWI5ZTgtNmJmMGRiYWY5Njg5IiwidCI6IjdkNDg3NDc4LWNhMjYtNDkxOS05MDlhLTBjNDU3MTQyYzczNCJ9&pageName=87f77b55a00e014be595)

![Promotional Campaign Analysis Dashboard](screenshots/overview.png)

## 📂 Data model 

→ `customers.csv`  

| Column               | Type        | Description                                |
|----------------------|------------|--------------------------------------------|
| customer_id       | text       | Unique customer ID (primary key)       |
| became_member_on       | date       | Date when the customer created their account (yyyymmdd)       |
| gender       | text       | Customer's gender: (M)ale, (F)emale, or (O)ther"       |
| age       | integer       | Customer's age       |
| income       | float       | Customer's estimated annual income, in USD       |

→ `offers.csv`  

| Column               | Type        | Description                                |
|----------------------|------------|--------------------------------------------|
| offer_id       | text       | Unique offer ID (primary key)      |
| offer_type       | text       | Type of offer: bogo (buy one, get one), discount, or informational      |
| difficulty       | integer       | Minimum amount required to spend in order to be able to complete the offer     |
| reward       | integer       | Reward ($) obtained by completing the offer    |
| duration       | integer       | Days a customer has to complete the offer once they have received it       |
| channels       | text       | List of marketing channels used to send the offer to customers      |
