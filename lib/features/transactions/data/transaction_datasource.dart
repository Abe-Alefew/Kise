import 'transaction_model.dart';

class TransactionDatasource {

  static List<TransactionModel> transactions = [

    // ── MAY ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "May 30", icon: "💼", month: "May"),
    TransactionModel(title: "Freelance",    category: "Freelance",     amount: 9000,  type: "Income",  date: "May 20", icon: "💻", month: "May"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "May 01", icon: "🏠", month: "May"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 4500,  type: "Expense", date: "May 10", icon: "🛒", month: "May"),
    TransactionModel(title: "Transport",    category: "Transport",     amount: 1800,  type: "Expense", date: "May 15", icon: "🚌", month: "May"),
    TransactionModel(title: "Netflix",      category: "Entertainment", amount: 600,   type: "Expense", date: "May 18", icon: "🎬", month: "May"),

    // ── APR ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Apr 30", icon: "💼", month: "Apr"),
    TransactionModel(title: "Investment",   category: "Investment",    amount: 5000,  type: "Income",  date: "Apr 12", icon: "📈", month: "Apr"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Apr 01", icon: "🏠", month: "Apr"),
    TransactionModel(title: "Education",    category: "Education",     amount: 12000, type: "Expense", date: "Apr 15", icon: "🎓", month: "Apr"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 5200,  type: "Expense", date: "Apr 10", icon: "🛒", month: "Apr"),
    TransactionModel(title: "Transport",    category: "Transport",     amount: 2100,  type: "Expense", date: "Apr 20", icon: "🚌", month: "Apr"),

    // ── MAR ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Mar 30", icon: "💼", month: "Mar"),
    TransactionModel(title: "Freelance",    category: "Freelance",     amount: 14000, type: "Income",  date: "Mar 22", icon: "💻", month: "Mar"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Mar 01", icon: "🏠", month: "Mar"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 3800,  type: "Expense", date: "Mar 08", icon: "🛒", month: "Mar"),
    TransactionModel(title: "Shopping",     category: "Shopping",      amount: 7500,  type: "Expense", date: "Mar 14", icon: "🛍️", month: "Mar"),
    TransactionModel(title: "Transport",    category: "Transport",     amount: 1500,  type: "Expense", date: "Mar 18", icon: "🚌", month: "Mar"),

    // ── FEB ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Feb 28", icon: "💼", month: "Feb"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Feb 01", icon: "🏠", month: "Feb"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 4200,  type: "Expense", date: "Feb 10", icon: "🛒", month: "Feb"),
    TransactionModel(title: "Medical",      category: "Health",        amount: 9000,  type: "Expense", date: "Feb 15", icon: "🏥", month: "Feb"),
    TransactionModel(title: "Transport",    category: "Transport",     amount: 1600,  type: "Expense", date: "Feb 20", icon: "🚌", month: "Feb"),

    // ── JAN ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Jan 30", icon: "💼", month: "Jan"),
    TransactionModel(title: "Bonus",        category: "Salary",        amount: 15000, type: "Income",  date: "Jan 05", icon: "🎁", month: "Jan"),
    TransactionModel(title: "Freelance",    category: "Freelance",     amount: 8000,  type: "Income",  date: "Jan 18", icon: "💻", month: "Jan"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Jan 01", icon: "🏠", month: "Jan"),
    TransactionModel(title: "New Year",     category: "Entertainment", amount: 11000, type: "Expense", date: "Jan 01", icon: "🎉", month: "Jan"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 5500,  type: "Expense", date: "Jan 12", icon: "🛒", month: "Jan"),

    // ── DEC ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Dec 30", icon: "💼", month: "Dec"),
    TransactionModel(title: "Investment",   category: "Investment",    amount: 12000, type: "Income",  date: "Dec 10", icon: "📈", month: "Dec"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Dec 01", icon: "🏠", month: "Dec"),
    TransactionModel(title: "Christmas",    category: "Shopping",      amount: 18000, type: "Expense", date: "Dec 24", icon: "🎄", month: "Dec"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 6000,  type: "Expense", date: "Dec 15", icon: "🛒", month: "Dec"),

    // ── NOV ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Nov 30", icon: "💼", month: "Nov"),
    TransactionModel(title: "Freelance",    category: "Freelance",     amount: 6000,  type: "Income",  date: "Nov 15", icon: "💻", month: "Nov"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Nov 01", icon: "🏠", month: "Nov"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 4000,  type: "Expense", date: "Nov 10", icon: "🛒", month: "Nov"),
    TransactionModel(title: "Transport",    category: "Transport",     amount: 1700,  type: "Expense", date: "Nov 20", icon: "🚌", month: "Nov"),

    // ── OCT ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Oct 30", icon: "💼", month: "Oct"),
    TransactionModel(title: "Investment",   category: "Investment",    amount: 7000,  type: "Income",  date: "Oct 08", icon: "📈", month: "Oct"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Oct 01", icon: "🏠", month: "Oct"),
    TransactionModel(title: "Education",    category: "Education",     amount: 10000, type: "Expense", date: "Oct 15", icon: "🎓", month: "Oct"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 4300,  type: "Expense", date: "Oct 10", icon: "🛒", month: "Oct"),

    // ── SEP ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Sep 30", icon: "💼", month: "Sep"),
    TransactionModel(title: "Freelance",    category: "Freelance",     amount: 11000, type: "Income",  date: "Sep 18", icon: "💻", month: "Sep"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Sep 01", icon: "🏠", month: "Sep"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 3900,  type: "Expense", date: "Sep 10", icon: "🛒", month: "Sep"),
    TransactionModel(title: "Shopping",     category: "Shopping",      amount: 5000,  type: "Expense", date: "Sep 22", icon: "🛍️", month: "Sep"),

    // ── AUG ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Aug 30", icon: "💼", month: "Aug"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Aug 01", icon: "🏠", month: "Aug"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 4100,  type: "Expense", date: "Aug 10", icon: "🛒", month: "Aug"),
    TransactionModel(title: "Transport",    category: "Transport",     amount: 2000,  type: "Expense", date: "Aug 15", icon: "🚌", month: "Aug"),

    // ── JUL ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Jul 30", icon: "💼", month: "Jul"),
    TransactionModel(title: "Freelance",    category: "Freelance",     amount: 16000, type: "Income",  date: "Jul 20", icon: "💻", month: "Jul"),
    TransactionModel(title: "Investment",   category: "Investment",    amount: 9000,  type: "Income",  date: "Jul 10", icon: "📈", month: "Jul"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Jul 01", icon: "🏠", month: "Jul"),
    TransactionModel(title: "Vacation",     category: "Travel",        amount: 22000, type: "Expense", date: "Jul 15", icon: "✈️", month: "Jul"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 4800,  type: "Expense", date: "Jul 08", icon: "🛒", month: "Jul"),

    // ── JUN ──────────────────────────────────
    TransactionModel(title: "Salary",       category: "Salary",        amount: 28000, type: "Income",  date: "Jun 30", icon: "💼", month: "Jun"),
    TransactionModel(title: "Rent",         category: "Housing",       amount: 8000,  type: "Expense", date: "Jun 01", icon: "🏠", month: "Jun"),
    TransactionModel(title: "Groceries",    category: "Food",          amount: 4000,  type: "Expense", date: "Jun 10", icon: "🛒", month: "Jun"),
    TransactionModel(title: "Transport",    category: "Transport",     amount: 1900,  type: "Expense", date: "Jun 18", icon: "🚌", month: "Jun"),
  ];
}