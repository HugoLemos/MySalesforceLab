public class CloneEmailMessagesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Describe the sObject type to get all fields
        Schema.DescribeSObjectResult describeResult = EmailMessage.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        
        // Construct the dynamic SOQL query to get all fields
        String soql = 'SELECT ' + String.join(fieldMap.keySet(), ', ') + ' FROM EmailMessage';
        return Database.getQueryLocator(soql);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<EmailMessage> newEmailMessages = new List<EmailMessage>();
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        Map<Id, EmailMessage> originalToNewEmailMessageMap = new Map<Id, EmailMessage>();
        
        // Iterate over the EmailMessages and clone them
        for (sObject sObj : scope) {
            EmailMessage originalEmailMessage = (EmailMessage) sObj;
            
            // Clone the EmailMessage
            EmailMessage newEmailMessage = originalEmailMessage.clone(false, true, false, false);
            newEmailMessage.TextBody = 'Content migrated to File';
            newEmailMessage.HtmlBody = 'Content migrated to File';
            newEmailMessage.ActivityId = null; // can't be cloned, hence needs to be cleared
            newEmailMessage.ParentId = originalEmailMessage.ParentId;
            newEmailMessage.RelatedToId = originalEmailMessage.RelatedToId;
            // newEmailMessage.ValidatedFromAddress = 'hl@email.com'; // required only for sandbox
            // newEmailMessage.FromAddress = 'hl@email.com'; // required only for sandbox
            newEmailMessages.add(newEmailMessage);
            
            originalToNewEmailMessageMap.put(originalEmailMessage.Id, newEmailMessage);
        }
        
        // Insert the cloned EmailMessages
        if (!newEmailMessages.isEmpty()) {
            
            insert newEmailMessages;
            
            // Create ContentVersion records for each new EmailMessage
            for (sObject sObj : scope) {
                
                EmailMessage originalEmailMessage = (EmailMessage) sObj;
                EmailMessage newEmailMessage = originalToNewEmailMessageMap.get(originalEmailMessage.Id);
                
                if (newEmailMessage != null) {
                    
                    // Compress the content
                    Compression.ZipWriter writer = new Compression.ZipWriter();
                    writer.addEntry('htmlBody_' + newEmailMessage.Id + '.html', Blob.valueOf(originalEmailMessage.HtmlBody != null ? originalEmailMessage.HtmlBody : ''));
                    writer.addEntry('textBody_' + newEmailMessage.Id + '.txt', Blob.valueOf(originalEmailMessage.TextBody != null ? originalEmailMessage.TextBody : '') );
                    blob zipAttachment = writer.getArchive();
                    
                    // add compressed content as a file
                    ContentVersion zipFile = new ContentVersion(
                        Title        = 'bodyZipArchive' ,
                        PathOnClient = 'bodyZipArchive.zip',
                        VersionData  = zipAttachment,
                        FirstPublishLocationId = newEmailMessage.Id,
                        IsMajorVersion = true
                    );
                    
                    contentVersions.add(zipFile);
                }
            }
            
            // Insert ContentVersion records
            if (!contentVersions.isEmpty()) {
                insert contentVersions;
            }
            
            // delete existing records;
            delete scope;
        } 
    }
    
    public void finish(Database.BatchableContext bc) {
        // Optionally, you can add some logic to execute after the batch job finishes
    }
}