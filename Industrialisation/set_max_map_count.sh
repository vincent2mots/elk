# Augmentation du parametre vm_max_map_count et vérification que tout est OK
echo "Augmentation du parametre vm_max_map_count"
sysctl -w vm.max_map_count=262144


# Redémarrage de Docker
echo "Redemarrage de Docker"
systemctl restart docker