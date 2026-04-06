/**
 * @description CS21-3595: Service class to build HTML email templates for RMA order Order Products
 * @author Vijay K R
 * @created 2025-09-16
 */
public with sharing class OrderRmaEmailTempBuilder {

    /**
     * @description Request wrapper class for invocable method input parameters
     * Flow will pass a collection of these, each containing a list of OrderItems
     */
    public class Request {
        @InvocableVariable(required=true)
        public List<OrderItem> orderItems;
    }

    /**
     * @description Response wrapper class for invocable method output
     */
    public class Response {
        @InvocableVariable
        public String htmlTable;
    }

    /**
     * @description Generates HTML table for OrderItems to be used in email templates
     * @param requests List of Request objects, each containing a list of OrderItems
     * @return List of Response objects with HTML tables
     */
    @InvocableMethod(label='Build RMA Table' description='Generate HTML table for RMA Order Products')
    public static List<Response> buildRmaTable(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();

            String html = '<table border="1" cellpadding="6" cellspacing="0" style="width:100%; border-collapse:collapse; text-align:center;">' +
                          '<tr style="background-color:#f2f2f2;">' +
                          '<th>Component type</th>' +
                          '<th>Defective serial number</th>' +
                          '<th>Replacement serial number</th>' +
                          '<th>Related asset serial number</th>' +
                          '<th>Replacement instructions</th>' +
                          '</tr>';

            // KB article links from mtd
            Map<String, Order_RMA_Shipment_KB_links__mdt> metaMap = Order_RMA_Shipment_KB_links__mdt.getAll();

            for (OrderItem oi : req.orderItems) {
                Order_RMA_Shipment_KB_links__mdt mtdRecord = oi.RMA_Component_Type__c != null ? metaMap.get(oi.RMA_Component_Type__c.replaceAll(' ', '_')) : null;
                html += '<tr text-align:center;>' +
                        '<td>' + (oi.RMA_Component_Type__c != null ? oi.RMA_Component_Type__c : 'N/A') + '</td>' +
                        '<td>' + ((oi.Failed_Serial_Number__c != null && oi.RMA_Component_Type__c != 'CMOS Battery') ? oi.Failed_Serial_Number__c : 'N/A') + '</td>' +
                        '<td>' + ((oi.SerialNumber__c != null && oi.RMA_Component_Type__c != 'CMOS Battery') ? oi.SerialNumber__c : 'N/A') + '</td>' +
                        '<td>' + ((oi.Assets__c != null && oi.RMA_Component_Type__c != 'CMOS Battery') ? oi.Assets__c : 'N/A') + '</td>';
                if (mtdRecord != null) {
                    html += '<td><a href="' + mtdRecord.Article_Link__c + '" target="_blank">Video guides and documentation</a></td>';
                } else {
                    html += '<td>N/A</td>';
                }
                html += '</tr>';
            }

            html += '</table>';
            res.htmlTable = html;

            results.add(res);
        }

        return results;
    }
}