#-----------------------------------------------------------------------------
# USAGE
#-----------------------------------------------------------------------------
#
#  make all ................. make install and setup
#  make install ............. install ISA in /var/www/html/${ISAROOT}
#  make setup ............... make setup for example corpus
#  make [VARIABLES] setup ... make setup for some other data
#
# VARIABLES to be set:
#
# ISAROOT ..... root dir for web data
# CORPUS ...... unique name of the corpus (without extension, no subdirectories)
#               (this will be used to store all data)
# SRCLANG ..... source language identifier (eg. en, sv, ...)
# TRGLANG ..... target language identifier (eg. en, sv, ...)
#
# SRC_FILE .... path to the source XML file (gzipped)
# TRG_FILE .... path to the target XML file (gzipped)
# ALG_FILE .... path to the sentece alignment file (gzipped)
#
#-----------------------------------------------------------------------------
# EXAMPLE:
#
# make 	CORPUS=mycorpus-xxyy SRCLANG=xx TRGLANG=yy \
#	SRC_FILE=xx/mycorpus.xml.gz \
#	TRG_FILE=yy/mycorpus.xml.gz \
#	ALG_FILE=xx-yy/mycorpus.xml.gz all
#
#############################################################################

VERSION  = 0.1


## example corpus and data - change if necessary

CORPUS  = RF-sven-1988
SRCLANG = en
TRGLANG = sv

SRC_FILE = example/RF/en/1988.xml.gz
TRG_FILE = example/RF/sv/1988.xml.gz
ALG_FILE = example/RF/en-sv/1988.xml.gz


## location of html files

WEBHOME = /var/www/html
ISAROOT = ISA
ISAHOME = ${WEBHOME}/${ISAROOT}




INSTALL = install -c
INSTALL_BIN = ${INSTALL} -m 755
INSTALL_DATA = ${INSTALL} -m 644

INSTALLFILES = 	${ISAHOME}/index.php \
		${ISAHOME}/isa.php ${ISAHOME}/isa.css \
		${ISAHOME}/doc/isa.html \
		$(patsubst %,${ISAHOME}/%,${wildcard include/*})


# UPLUG = path to uplug start script
# UPLUGSHARE = home directory of shared data
# SENTALIGNER = default alignment program (Gale&Church)

ifndef UPLUG
  UPLUG       = $(shell which uplug)
endif
ifndef UPLUGSHARE
  UPLUGSHARE  = $(shell perl -e 'use Uplug::Config;print &shared_home();')
endif
ifndef SENTALIGNER
  SENTALIGNER = $(shell perl -e 'use Uplug::Config;print find_executable("align2");')
endif


LANGPAIR     = $(SRCLANG)-$(TRGLANG)
INVLANGPAIR  = $(TRGLANG)-$(SRCLANG)
DATADIR      = corpora/${CORPUS}

## local files
SRCXML       = ${DATADIR}/${SRCLANG}.xml
TRGXML       = ${DATADIR}/${TRGLANG}.xml

SENTALIGN    = ${DATADIR}.ces
SENTALIGNIDS = ${DATADIR}.ids

# configuration files
CONFIG       = $(DATADIR)/config.inc
ISACONFIG    = $(DATADIR)/config.isa


all: 	install setup

setup:	${ISAHOME}/$(SRCXML) ${ISAHOME}/$(TRGXML) \
	${ISAHOME}/$(SENTALIGN) \
	${ISAHOME}/$(CONFIG)

install: ${INSTALLFILES} ${ISAHOME}/$(DATADIR)


${INSTALLFILES}: ${ISAHOME}/%: %
	mkdir -p ${dir $@}
	${INSTALL_DATA} $< $@

${ISAHOME}/$(DATADIR):
	mkdir -p $(dir $@)
	chown www-data:www-data $(dir $@)
	chmod +s $(dir $@)
	mkdir -p $@
	chown www-data:www-data $@


${ISAHOME}/$(SENTALIGN): ${ALG_FILE}
	mkdir -p ${dir $@}
	gzip -cd $< > $@


${ISAHOME}/$(SRCXML): $(SRC_FILE)
	mkdir -p ${dir $@}
ifeq ($(shell zgrep '<w' ${SRC_FILE}),)
	zcat $< | grep -v '<time ' |\
	$(UPLUG) pre/tok -l ${SRCLANG} -out $@
else
	zcat $< | grep -v '<time ' > $@
endif

${ISAHOME}/$(TRGXML): $(TRG_FILE)
	mkdir -p ${dir $@}
ifeq ($(shell zgrep '<w' ${SRC_FILE}),)
	zcat $< | grep -v '<time ' |\
	$(UPLUG) pre/tok -l ${TRGLANG} -out $@
else
	zcat $< | grep -v '<time ' > $@
endif


${ISAHOME}/$(CONFIG): ${ISAHOME}/$(DATADIR)/%.inc: include/%.in ${ISAHOME}/$(SRCXML) ${ISAHOME}/$(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#${DATADIR}#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%UPLUGSHARE%%#$(UPLUGSHARE)#' |\
	sed 's#%%SENTALIGNER%%#$(SENTALIGNER)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

${ISAHOME}/$(ISACONFIG): ${ISAHOME}/$(DATADIR)/%.isa: include/%.in ${ISAHOME}/$(SRCXML) ${ISAHOME}/$(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#${DATADIR}#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%UPLUGSHARE%%#$(UPLUGSHARE)#' |\
	sed 's#%%SENTALIGNER%%#$(SENTALIGNER)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

clean:
	rm -f config.inc
	rm -f $(SENTALIGNIDS)

