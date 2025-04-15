public with sharing class HL_LoadEmailMessageController {

    @AuraEnabled(cacheable=true)
    public static EmailMessageContent getEmailMessageBody(Id recordId) {

        EmailMessageContent message = new EmailMessageContent();

        try {
            // Query the most recent Attachment related to the record
            ContentVersion content = [
                SELECT VersionData
                FROM ContentVersion
                WHERE FirstPublishLocationId = :recordId
                    AND Title = 'bodyZipArchive'
                LIMIT 1
            ];

            Compression.ZipReader reader = new Compression.ZipReader(content.VersionData);
            message.htmlBody = reader.extract('htmlBody.html')?.toString();
            message.textBody = reader.extract('textBody.txt')?.toString();

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving zip entry: ' + e.getMessage());
        }

        return message;
    }

    public class EmailMessageContent {
        @AuraEnabled public String htmlBody {get; set;}
        @AuraEnabled public String textBody {get; set;}
    }
}
