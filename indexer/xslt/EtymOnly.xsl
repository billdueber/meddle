<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
    <xsl:import href="./indexer/xslt/Common.xsl"/>
           <xsl:output method="html" indent="yes"/>
   
    <xsl:template match="/ETYM">
        <span class="ETYM">
                <xsl:apply-templates/>
        </span>
    </xsl:template>
      
    <xsl:template match="LANG">
        <!--XXX Do we need mouseover stuff here for abbreviations-->
        <span class="LANG">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="LG">
        <span class="LG">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!-- May need to deal with <XREF> and /XREF/POS
        within <ETYM> PFS says ignore XREF 
        Waiting for PFS response on POS
    -->
</xsl:stylesheet>