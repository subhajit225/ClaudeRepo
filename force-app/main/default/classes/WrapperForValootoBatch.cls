public Class WrapperForValootoBatch {

    public class CLIWrapper{
        public Map<Id, ContractLineItem> cliAndClonedCLI{get; set;}
        public Map<Id, List<Entitlement>> cliAndEntitlement{get; set;}
        public Map<Id, List<Asset>> cliAndAsset{get; set;}
    }
}