PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;
INSERT INTO racer VALUES(1,1,'FRA','Paris','Urban cycle',1,'A','','');
INSERT INTO racer VALUES(2,2,'FRA','Paris','Urban cycle',1,'B','','');
INSERT INTO racer VALUES(3,3,'FRA','Paris','Urban cycle',2,'C','','');
INSERT INTO racer VALUES(4,4,'FRA','Paris','Urban cycle',1,'D','','');
INSERT INTO racer VALUES(5,5,'FIN','Paris','Cycl''air',1,'E','','');
INSERT INTO racer VALUES(6,6,'FIN','Paris','V�loCit� Paris',1,'F','','');

INSERT INTO race VALUES(1,'Main Race Qualification',NULL,0);
INSERT INTO race VALUES(2,'Main Race Final','2010-05-16T14:00:00.000',0);
-- Qualification start times
INSERT INTO timelog VALUES(1,1,'2010-05-16T09:00:00.000');
INSERT INTO timelog VALUES(1,2,'2010-05-16T09:00:30.000');
INSERT INTO timelog VALUES(1,3,'2010-05-16T09:01:00.000');
INSERT INTO timelog VALUES(1,4,'2010-05-16T09:01:30.000');
INSERT INTO timelog VALUES(1,5,'2010-05-16T09:02:00.000');
INSERT INTO timelog VALUES(1,6,'2010-05-16T09:02:30.000');
-- Qualification finish times
INSERT INTO timelog VALUES(1,1,'2010-05-16T09:24:49.000');
INSERT INTO timelog VALUES(1,2,'2010-05-16T09:25:39.000');
INSERT INTO timelog VALUES(1,3,'2010-05-16T09:26:12.000');
INSERT INTO timelog VALUES(1,4,'2010-05-16T09:27:05.000');
INSERT INTO timelog VALUES(1,5,'2010-05-16T09:30:58.000');
INSERT INTO timelog VALUES(1,6,'2010-05-16T09:27:41.000');
COMMIT;
