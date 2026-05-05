# Project Title - Kise(ኪሴ): A Financial tracking and budget planning mobile app for students.

## Description

Kise is an offline-first mobile app designed to help university students track their incomes and expenses in a financially constrained environment. The core features of our app are aimed at alleviating the mental stress of juggling monthly costs in our head and making students aware of their financial status at every moment. We believe this will help students spend smarter and develop discipline over their finances. 

## Group Members
### Section - 2
| Name | ID NO. |
| :--- | :--- |
| 1. Abraham Alemtesfa | UGR/9689/16 |
| 2. Betsinat Wendwesen | UGR/2787/16 |
| 3. Efrata Melese | UGR/6776/16 |
| 4. Kirubel Wubet | UGR/7041/16 |
| 5. Zeamanuel Mebit | UGR/9677/16 |

## Features

### 1. Authentication and Authorization

* **User Registration and Login:** Users can securely sign up and log in using a custom backend authentication system with JWT and Bcrypt, independent of BaaS platforms like Firebase.
* **Logout:** Users can securely clear their local session and log out of their accounts.
* **Authorization:** The system uses Bearer tokens to protect endpoints, ensuring users can only access and modify their own personal financial data and goals.

### 2. Business Features and CRUD Operations

#### Transaction Management
* **Create:** Users can add new income and expense records, specifying amount, source such as cash, bank, or mobile money, category, and date.
* **Read:** Users can view their transaction history, filter by date or type, and see periodic analytics such as daily, weekly, and monthly summaries.
* **Update:** Users can edit previously logged transactions to correct amounts, categories, or descriptions.
* **Delete:** Users can remove transactions that were logged incorrectly.

#### Financial Goal Management
* **Create:** Users can define specific financial targets such as daily, weekly, monthly, or yearly savings goals.
* **Read:** Users can track their progress toward active goals, viewing visual progress bars updated by their income and expense logic.
* **Update:** Users can adjust their goal parameters, such as extending the timeline or increasing the target amount.
* **Delete:** Users can delete goals that are completed or no longer relevant.

#### Dynamic Allowance and Insights Management
* **Create/Update:** Users can define and adjust an allowance cycle, such as a monthly stipend, to calculate a safe daily spending limit.
* **Read:** The system reads transaction behaviors to assign a spending personality, such as Balanced, Spender, or Saver, and generates rule-based alerts such as low balance warnings and category spike detections.

#### Debt, Lending & Adjustable Balance Tracking

* **Create:** Users can record money they lend to others or borrow from others by specifying the person’s name, amount, type (lent or borrowed), date, and optional notes.
* **Read:** Users can view all records categorized into **money owed to them** and **money they owe**, track remaining balances, and monitor repayment status (pending, partial, settled). Users can also toggle between **actual balance** and **adjusted balance** (including lent money).
* **Update:** Users can edit debt details and record partial repayments, with the system automatically updating the remaining balance.
* **Delete:** Users can remove incorrect records or automatically clear entries once the debt is fully settled.

