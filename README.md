# my-sync
Rsync like script for making backups  
usage : ./my-sync.bash <source> <destination>  


Creates a backup folder inside destination and commit changes into /backup/.files.  
After that, it makes an hardlink backup folder with the datetime of the backup such as:  


<destination>  
  
--backup  
  
--backup_2023-10-08-23-05-13  

