nodes = [
      {
         name: "master-1", 
         memory: 3072,
         cpus: 4,
         network: "private_network",
         ip: "192.168.56.11"
      },
      {
         name: "master-2", 
         memory: 3072,
         cpus: 4,
         network: "private_network",
         ip: "192.168.56.12"
      },
      {
         name: "master-3", 
         memory: 3072,
         cpus: 4,
         network: "private_network",
         ip: "192.168.56.13"
      },
      {
         name: "worker-1", 
         memory: 2048,
         cpus: 2,
         network: "private_network",
         ip: "192.168.56.21"
      },
      {
         name: "worker-2", 
         memory: 2048,
         cpus: 2,
         network: "private_network",
         ip: "192.168.56.22"
      },
      {
         name: "worker-3", 
         memory: 2048,
         cpus: 2,
         network: "private_network",
         ip: "192.168.56.23"
      },
      {
         name: "loadbalancer",  
         memory: 512,
         cpus: 1,
         network: "private_network",
         ip: "192.168.56.30"
      }
   ]