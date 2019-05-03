# azurehubandspoke
Azure Hub and Spoke (NVA)

With thanks to @CISCORouting on YouTube i deployed this in Azure for a VNET hub and spoke solution.  

https://www.youtube.com/watch?v=K0i25-Dxrcw

Similar to the original AWS Transit VPC solution but without the Lambda automation.

The design uses peering between the hub and spoke but does not require peering between spokes which avoids a full peer mesh.

**NOTE** A few hours of head scratching was spending getting this working due to the network interface having ip forwarding disabled by default.

See documentation here: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview

#Overview

This solution simulates onprem using a single CSR which peers with the hub routers using eBGP over IPSEC.  
This could just as easily be an onprem firewall via express route or a CSR in AWS for example as it uses public to public.

**NOTE** This requires a modification to the security group to allow UDP500 for the IPSEC to come up, all other traffic is encrpted over the tunnel.

The backup CSR uses as path prepend to control the routing to prefer RTR1 although at the time of writing this has not been tested with the Azure LB.

#Diagram

/Azure_HubandSpokev9-Cisco Hub Solution with LB.png
