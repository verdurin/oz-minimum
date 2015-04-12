IMAGES = centos65 centos65-epel centos71

OZ_CFG = oz.cfg
DATA_DIR = ~/.oz

.PHONY:all
all: $(IMAGES)

centos65: centos65.x86_64.qcow2
centos65-epel: centos65-epel.x86_64.qcow2
centos71: centos71.x86_64.qcow2

$(OZ_CFG): $(OZ_CFG).in
	sed 's#%data_dir%#$(DATA_DIR)#g' $^ > $@

%.x86_64.qcow2: $(OZ_CFG) %.ks %.tdl
	oz-install -c $(OZ_CFG) -p -u -d3 -a $*.ks -x $*-libvirt.xml $*.tdl
	qemu-img convert -c $(DATA_DIR)/images/$@ -O qcow2 $@
	rm -rf $(DATA_DIR)/icicletmp/$*.x86_64
	rm -f $(DATA_DIR)/images/$@

.PHONY:clean
clean:
	echo y | oz-cleanup-cache -c $(OZ_CFG)
	rm -f $(OZ_CFG) *.xml *.qcow2
