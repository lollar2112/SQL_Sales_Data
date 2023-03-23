select * from dbo.sales_data_sample

select PRODUCTLINE, sum(sales) Revenue
from dbo.sales_data_sample
group by PRODUCTLINE
order by sum(sales) desc

select YEAR_ID, sum(sales) Revenue
from dbo.sales_data_sample
group by YEAR_ID
order by sum(sales) desc

--- lower profits in 2005

select distinct MONTH_ID from dbo.sales_data_sample
where year_id = 2005

--- Only 5 months of operation in 2005

select DEALSIZE, sum(sales) Revenue
from dbo.sales_data_sample
group by DEALSIZE
order by sum(sales) desc

select MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from dbo.sales_data_sample
where YEAR_ID = 2004
group by MONTH_ID 
order by sum(sales) desc

select MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from dbo.sales_data_sample
where YEAR_ID = 2004 AND MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE
order by sum(sales) desc


DROP TABLE IF EXISTS #rfm
;with rfm as
(
SELECT
	CUSTOMERNAME,
	sum(sales) MonetaryValue,
	avg(sales) AvgMonetaryValue,
	count(ORDERDATE) Frequency,
	max(ORDERDATE) last_order_date,
	(select max(ORDERDATE) from dbo.sales_data_sample) max_order_date,
	DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from dbo.sales_data_sample)) Recency
from dbo.sales_data_sample
group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)

select c.*, rfm_recency+ rfm_frequency + rfm_monetary as frm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar)rfm_cell_string
	into #rfm
from rfm_calc c


select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	case
		when rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers' --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' --big spenders that haven't purchased in a while going away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333, 321, 422, 332, 432) then 'active' --customers that bave bought often and recently but at low price points
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm



--which products are normally sold together?

---SELECT * FROM dbo.sales_data_sample WHERE ORDERNUMBER = 10411

select distinct OrderNumber, stuff(

(select ',' + PRODUCTCODE
from dbo.sales_data_sample p
where ORDERNUMBER in 
	(

select ORDERNUMBER
from(
	select ORDERNUMBER, count(*) rn
	from dbo.sales_data_sample
	where STATUS = 'Shipped'
	group by ORDERNUMBER
)m
where rn = 2
)
and p.ORDERNUMBER = s.ORDERNUMBER
FOR XML PATH (''))

, 1, 1, '') ProductCode

from dbo.sales_data_sample s
order by 2 desc

