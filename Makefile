##  Makefile to run the generate the directorys where to run the
##  reduction of the EVLA B-configuration data of
##  IRAS 05327+3404
##
##  O. Morata
##  2018
##

PRJ_NAME=EVLA-IRAS_05327+3404

BANDS = X K Q C

ROOT_DIR=/almalustre/home/omorata

HOME_DIR=.

BIN_DIR=$(HOME_DIR)/scripts
CFG_DIR=$(HOME_DIR)/config
DATA_DIR=$(HOME_DIR)/data
REDC_DIR=$(HOME_DIR)/reduction
RES_DIR=$(HOME_DIR)/results

EXTDATA_DIR=$(ROOT_DIR)/Data/EVLA/$(PRJ_NAME)
#EXTSCRIPT_DIR=$(ROOT_DIR)/scripts
EXTREDC_DIR=$(ROOT_DIR)/Reductions/$(PRJ_NAME)

CHECK_DIR=results



#-- define templates ---------------------------------------------------


# template to define the rules to unpack the data files in the reductions
# directory and also to delete the given band reduction directory
#
define Unpack_Template
unpack-$(1):
	if [ ! -d $(REDC_DIR)/band_$(1) ]; \
	then sh $(BIN_DIR)/bash/unpackms.sh \
	    $(CFG_DIR)/calibration/band_$(1)/$(1)-unpack.conf; \
	fi


clean-$(1): 
	rm -Rf cd reduction/band_$(1)
endef


#-- end definition of templates ----------------------------------------

unpackstr =
cleanpackstr=
$(foreach band, $(BANDS), \
    $(eval unpackstr += $(addsuffix $(band),unpack-)) \
    $(eval cleanpackstr += $(addsuffix $(band),clean-)) \
)


export

.PHONY: init erase unpack cleanpack

all:

unpack: $(unpackstr)

cleanpack : $(cleanpackstr)

# automatically generate targets for unpacking 
$(foreach band, $(BANDS), \
    $(eval $(call Unpack_Template,$(band))) \
)


init:
	sh $(BIN_DIR)/bash/mk_iras_struct.sh


clean: clean_reduction
	rm -Rf results
	rm -f data


clean_reduction:
	(cd reduction && rm -Rf band*)
	rm -Rf reduction
