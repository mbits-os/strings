TRANSLATE=../translate/
include $(TRANSLATE)/*.mak
INPUT_FILE=$(TRANSLATE)site_strings.txt
POT_FILE=$(TRANSLATE)site_strings.pot
CLIENT_FILES=../httpd/www/code/lang/
LOCALES_DIR=../httpd/data/locales
EXPORTS=client.strings
EXPORT_INPUT=$(TRANSLATE)$(EXPORTS)
CPS_IN= \
	iso-8859-1 \
	iso-8859-2 \
	iso-8859-3 \
	iso-8859-4 \
	iso-8859-5 \
	iso-8859-6 \
	iso-8859-8 \
	iso-8859-9 \
	iso-8859-15 \
	koi8-r \
	koi8-u \
	windows-437 \
	windows-720 \
	windows-737 \
	windows-775 \
	windows-850 \
	windows-852 \
	windows-855 \
	windows-857 \
	windows-858 \
	windows-862 \
	windows-866 \
	windows-874 \
	windows-1250 \
	windows-1251 \
	windows-1252 \
	windows-1253 \
	windows-1254 \
	windows-1255 \
	windows-1256 \
	windows-1257 \
	windows-1258

Q=@

ECHO=echo
TOUCH=touch
XGETTEXT=xgettext
MSGFMT=msgfmt
MSGINIT=python ./code/msginit.py
MSGMERGE=msgmerge
DEPLOY=python ./code/extract.py
EXTRACT=python ./code/strings.py
DEFINE=python ./code/defines.py
EXPORT=python ./code/export.py
CPS_PY=python ./code/cp.py
CHARSET_MERGE=python ./code/charsets.py
MKDIR=mkdir -p
CP=cp -f
RM=rm -f

SAVE_LANGS = $(subst -,_,$(LANGS))
POS = $(addprefix $(TRANSLATE), $(addsuffix /site_strings.po,$(SAVE_LANGS)))
MOS = $(addprefix $(TRANSLATE), $(addsuffix /site_strings.mo,$(SAVE_LANGS)))
LNGS = $(addprefix $(LOCALES_DIR)/, $(addsuffix /site_strings.lng,$(SAVE_LANGS)))
EXPORTED = $(addprefix $(CLIENT_FILES), $(addsuffix .js, $(foreach file, $(patsubst %.strings,%-,$(EXPORTS)), $(foreach lang, $(SAVE_LANGS), $(file)$(lang)))))
SAFE_CPS = $(subst -,_,$(CPS_IN))
CPS = $(addprefix ../int/strings/charset/,$(addsuffix .dat,$(SAFE_CPS)))
CPS_TXT = $(addprefix ./charset/,$(addsuffix .txt,$(SAFE_CPS)))
CHARSET_DB = $(LOCALES_DIR)/charset.db
MAIL_SET = $(foreach lang, $(SAVE_LANGS), $(foreach mail, $(MAIL), $(lang)/$(mail)))
MAIL_IN = $(addprefix $(TRANSLATE), $(MAIL_SET))
MAIL_OUT = $(addprefix $(LOCALES_DIR)/, $(MAIL_SET))

get-locale=$(subst _,-,$(word 3,$(subst /, ,$1)))
get-locale-2=$(subst _,-,$(word 5,$(subst /, ,$1)))

all: $(DEFINES_FILE) $(LNGS) $(EXPORTED) $(MAIL_OUT) $(CHARSET_DB)

help:
	$(Q)$(ECHO) -e "Targets are:\n    all\n    clean\n    help\n    update - extract new strings and distribute them\n    msgs - compile .mo files\n    check - test unused and duplicate strings"

update: $(POT_FILE) $(POS)

check:
	@python ./code/duplicates.py
	@python ./code/unused.py

clean:
	$(Q)$(RM) $(MOS)
	$(Q)$(RM) $(LNGS)
	$(Q)$(RM) $(DEFINES_FILE)
	$(Q)$(RM) $(EXPORTED)
	$(Q)$(RM) $(MAIL_OUT)
	$(Q)$(RM) $(CHARSET_DB) $(CPS)

msgs: $(MOS)

.PHONY: all clean update help check msgs

$(DEFINES_FILE): $(INPUT_FILE)
	$(Q)$(ECHO) "[ENUM]" $(notdir $@)
	$(Q)$(MKDIR) $(LOCALES_DIR)
	$(Q)$(DEFINE) $(INPUT_FILE) $(DEFINES_FILE)
	@python ./code/duplicates.py
	@python ./code/unused.py

$(POT_FILE): $(INPUT_FILE)
	$(Q)$(ECHO) "[LANG]" $@
	$(Q)$(MKDIR) $(LOCALES_DIR)
	$(Q)$(EXTRACT) $(INPUT_FILE) $(POT_FILE)

%.mo: %.po
	$(Q)$(ECHO) "[ MO ]" $(call get-locale,$@)
	$(Q)$(MKDIR) $(dir $@)
	$(Q)$(MSGFMT) -c -o $@ $<

$(LNGS): $(MOS)
	$(Q)$(ECHO) "[LANG]" $(call get-locale-2,$@)
	$(Q)$(MKDIR) $(dir $@)
	$(Q)$(DEPLOY) $(INPUT_FILE) $(TRANSLATE)$(subst -,_,$(call get-locale-2,$@))/site_strings.mo $@ $(call get-locale-2,$@)

init-command=$(MSGINIT) $2 $(subst _,-,$(subst /site_strings.po,,$1)) > $1
merge-command=$(MSGMERGE) -o $1 $1 $2 2>/dev/null

$(EXPORTED): $(LNGS) $(EXPORT_INPUT)
	$(Q)$(MKDIR) $(dir $@)
	$(Q)$(EXPORT) $(INPUT_FILE) site_strings.mo $@

$(POS): $(POT_FILE)
	$(Q)$(ECHO) $(if $(wildcard $@),"[LANG]","[NEW ]") $(call get-locale,$@)
	$(Q)$(MKDIR) $(dir $@)
	$(Q)$(if $(wildcard $@),$(call merge-command,$@,$<),$(call init-command,$@,$<))

$(CHARSET_DB): ./charset/aliases.txt $(CPS)
	$(Q)$(ECHO) "[ DB ]" $@
	$(Q)$(MKDIR) $(dir $@)
	$(Q)$(CHARSET_MERGE) $@ $^

../int/strings/charset/%.dat: ./charset/%.txt
	$(Q)$(ECHO) "[ CH ]" $(subst _,-,$(*F))
	$(Q)$(MKDIR) $(dir $@)
	$(Q)$(CPS_PY) $< $@ 

$(MAIL_OUT): $(MAIL_IN)
	$(Q)$(ECHO) "[ CP ]" $(patsubst $(LOCALES_DIR)/%,%,$@)
	$(Q)$(CP) $(patsubst $(LOCALES_DIR)/%,$(TRANSLATE)%,$@) $@ 

