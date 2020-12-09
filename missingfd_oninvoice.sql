SELECT
acqinv.inv_ident,
acqlid.id,
acqlid.fund_debit,
acqlid.lineitem as lineitem_id,
acqf.code,
acqf.year
FROM acq.lineitem_detail acqlid
join acq.invoice_entry acqie on acqie.lineitem=acqlid.lineitem
join acq.invoice acqinv on acqinv.id=acqie.invoice
left join acq.fund_debit acqfd on acqfd.id=acqlid.fund_debit
left join acq.fund acqf on acqf.id=acqfd.fund
where acqinv.inv_ident='B5930840'
order by acqlid.fund_debit asc;
