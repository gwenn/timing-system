-- Reset database
---- Purge generated data
delete from result;
delete from resultHisto;
delete from resultVersion;
delete from position;
---- Reset races status
update race set status = 0;
---- Remove timelogs
delete from timelog;
---- Reset races startTime
update race set startTime = null;
