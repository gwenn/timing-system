PRAGMA foreign_keys=ON;
PRAGMA recursive_triggers=ON;
BEGIN TRANSACTION;
INSERT INTO racer VALUES(NULL,1,'FRA','Paris','Urban cycle',1,'A','','');
INSERT INTO racer VALUES(NULL,2,'FRA','Paris','Urban cycle',1,'B','','');
INSERT INTO racer VALUES(NULL,3,'FRA','Paris','Urban cycle',2,'C','','');
INSERT INTO racer VALUES(NULL,4,'FRA','Paris','Urban cycle',1,'D','','');
INSERT INTO racer VALUES(NULL,5,'FIN','Paris','Cycl''air',1,'E','','');
INSERT INTO racer VALUES(NULL,6,'FIN','Paris','VéloCité Paris',1,'F','','');

INSERT INTO race VALUES(NULL,'Main Race Qualification',1,NULL,0);
INSERT INTO race VALUES(NULL,'Main Race Final',0,NULL,0);
COMMIT;
