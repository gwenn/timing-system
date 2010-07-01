PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;
INSERT INTO racer VALUES(NULL,1,'FRA','Paname','World Company',1,'Foo1','Bar','');
INSERT INTO racer VALUES(NULL,2,'FRA','Paname','Urban cycle',1,'Foo2','Bar','');
INSERT INTO racer VALUES(NULL,3,'FRA','Paname','Urban cycle',2,'Fooe','Bar','');
INSERT INTO racer VALUES(NULL,4,'FRA','Paname','Urban cycle',1,'Foo4','Bar','');
INSERT INTO racer VALUES(NULL,5,'FIN','Paname','Cycl''air',1,'Foo5','Bar','');
INSERT INTO racer VALUES(NULL,6,'FIN','Paname','VéloCité Paris',1,'Foo6','Bar','');

INSERT INTO race VALUES(NULL,'Main Race Qualification',1,NULL,0);
INSERT INTO race VALUES(NULL,'Main Race Final',0,NULL,0);
COMMIT;
