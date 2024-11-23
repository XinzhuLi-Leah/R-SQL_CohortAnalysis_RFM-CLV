create view CLV as
select 
		tmp1.CustomerID,
        tmp1.Country,
		total_money,
        total_orders,
        date(first_buying_date) as first_buying_date,
        date(last_buying_date) as  last_buying_date,
  case when timestampdiff(day, first_buying_date, last_buying_date) = 0 
      then 'One-Time Customer'
      else 'Returning Customer'
      end as CustomerType,
      timestampdiff(day, first_buying_date, last_buying_date) as diff,
  case when timestampdiff(day, first_buying_date, last_buying_date) = 0 
         then log(1 + (total_money / total_orders))
         else log(1 + ((total_money / total_orders) / timestampdiff(day, first_buying_date, last_buying_date)))
    end as LogTransformedMonthlyCLV
from 
(select 
     CustomerID,
     Country,
     count(distinct InvoiceNo) as total_orders,
     round(sum(UnitPrice*Quantity),0) as total_money
from OnlineRetail
where Quantity >0 and CustomerID is not null
group by CustomerID, Country) as tmp1	
left join 
(select 
       CustomerID,
       Country,
      min(InvoiceDate) as first_buying_date,
      max(InvoiceDate) as last_buying_date
FROM OnlineRetail
where Quantity >0 and CustomerID is not null
group by CustomerID ,Country
      ) as tmp2
on tmp1.CustomerID = tmp2.CustomerID ;


SELECT 
    CustomerID,
    Country,
    DailyCLV,
    round(DailyCLV * 365,0) as YearlyCLV,
    CASE 
        WHEN DailyCLV * 365 <= 600 THEN 'Low CLV Value'
        WHEN DailyCLV * 365 BETWEEN  600 AND 3000 THEN 'Medium CLV Value'
        WHEN DailyCLV * 365 > 3000 THEN 'High CLV Value'
    END AS CLVCategory,
    CustomerType
FROM CLV
where CustomerType != 'One-Time Customer';