@isTest (SeeAllData = true) 
public class dataGeneratorTest {
    
    static testmethod void testmethod1(){
          Test.startTest();
          FSLDataGenerator fdg = new FSLDataGenerator();
            fdg.generateData();
            fdg.reGenerateData();
          Test.stopTest();
    }
   
    static testmethod void testmethod2(){
        FSLDataGenerator fdg = new FSLDataGenerator();
        fdg.priority='Random';
        fdg.generateData();
        Test.startTest();
        system.assertEquals(true,fdg.priorityWasRandom);
        Test.stopTest();
    }
    
    static testmethod void testmethod3(){
        FSLDataGenerator fdg = new FSLDataGenerator();
        fdg.numWosToCreate = 1;
        fdg.randomServiceTerritory = false;
        fdg.randomWorkType = false;
        fdg.workTypeDecision = 'wo';
        fdg.workTypeChoice = [select id from worktype order by id asc limit 1].id;
        fdg.territoryChoice = [select id from serviceterritory order by id asc limit 1].id;
        fdg.earlyStart = '2019-05-01';
        fdg.dueDate = '2019-05-02';
        worktype wt = [select id, name from worktype order by id asc limit 1];
        serviceterritory st = [select id, name from serviceterritory order by id asc limit 1];
        
        workorder wo = new WorkOrder(Subject=wt.Name+' Job', WorkTypeId=wt.id, ServiceTerritoryId=st.id, Priority=null);
        list<workorder> wos = new list<workorder>();
        wos.add(wo);
        
        fdg.generateData();
        Test.startTest();
        system.assertEquals(wos.size(),fdg.wos.size());
        Test.stopTest();
    }
    
    static testmethod void testmethod4(){
        FSLDataGenerator fdg = new FSLDataGenerator();
        fdg.numWosToCreate = 1;
        fdg.randomServiceTerritory = true;
        fdg.randomWorkType = true;
        fdg.workTypeDecision = 'woli';
        fdg.workTypeChoice = [select id from worktype order by id asc limit 1].id;
        fdg.territoryChoice = [select id from serviceterritory order by id asc limit 1].id;
        fdg.priority = 'Random';
        fdg.priorityWasRandom = true;
        fdg.generateWolis = true;
        fdg.numWolisToCreate = 1;
        fdg.earlyStart = '2019-05-01';
        fdg.dueDate = '2019-05-02';
        fdg.workTypeDecision='b';
        fdg.randomizeAddresses=true;
        fdg.distance=1;
        fdg.distanceUnit='mi';
        fdg.generateData();
    }
}