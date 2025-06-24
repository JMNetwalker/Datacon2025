---Master DB
CREATE LOGIN JuanEMoreno WITH PASSWORD = 'Antiguo—s135!641'

--For Every database
CREATE USER JuanEMoreno FROM LOGIN JuanEMoreno;
ALTER ROLE db_owner ADD MEMBER JuanEMoreno;

---Users
CREATE LOGIN UserDataCon1 WITH PASSWORD = 'Tuesday202501!01'
CREATE LOGIN UserDataCon2 WITH PASSWORD = 'Tuesday202502!02'
CREATE LOGIN UserDataCon3 WITH PASSWORD = 'Tuesday202503!03'
CREATE LOGIN UserDataCon4 WITH PASSWORD = 'Tuesday202504!04'

--For Every database
CREATE USER UserDataCon1 FROM LOGIN UserDataCon1;
ALTER ROLE db_owner ADD MEMBER UserDataCon1;
CREATE USER UserDataCon2 FROM LOGIN UserDataCon2;
ALTER ROLE db_owner ADD MEMBER UserDataCon2;
CREATE USER UserDataCon3 FROM LOGIN UserDataCon3;
ALTER ROLE db_owner ADD MEMBER UserDataCon3;
CREATE USER UserDataCon4 FROM LOGIN UserDataCon4;
ALTER ROLE db_owner ADD MEMBER UserDataCon4;