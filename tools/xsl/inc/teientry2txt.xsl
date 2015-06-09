<?xml version='1.0' encoding='UTF-8'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.pnp-software.com/XSLTdoc"
  version="1.0">

  <xsl:include href="indent.xsl"/>

  <xsl:strip-space elements="*"/>

  <xsl:variable name="stylesheet-entry_svnid">$Id$</xsl:variable>

  <!-- I am fully aware of introducing some project-specific features into the P5 mode,
     but let this stuff reside here for a while until we come up with a clean way to 
     import project-dependent overrides from the individual project directories... -PB 13-apr-09-->

  <!-- TEI entry specific templates -->
  <xsl:template match="tei:entry">
    <xsl:apply-templates select="tei:form"/>
    <!-- force form before gramGrp -->
    <xsl:apply-templates select="tei:gramGrp"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="tei:sense | tei:note"/>
  </xsl:template>

  <xsl:template match="tei:form">
    <xsl:variable name="paren"
      select="count(child::tei:orth) and (count(parent::tei:form) = 1 or @type='infl')"/>
    <!-- parenthesized if nested or (ad hoc) if @type="infl" -->
    <!-- further adhockishness (I'm duly ashamed): you'd better check if the <orth> is really there, because you may be 
      looking at nested <form>s; a rewrite is needed here -->
    <xsl:if test="$paren">
      <xsl:text> (</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="tei:usg"/>
    <!-- added to handle usg info in nested <form>s -->
    <xsl:for-each select="tei:orth">
      <xsl:choose>
        <!-- values from the TEI Guidelines -->
        <xsl:when test="count(@extent)=0 or @extent='full'">
          <xsl:value-of select="."/>
        </xsl:when>
        <xsl:when test="@extent='pref'">
          <xsl:value-of select="concat(.,'-')"/>
        </xsl:when>
        <xsl:when test="@extent='suff'">
          <xsl:value-of select="concat('-',.)"/>
        </xsl:when>
        <xsl:when test="@extent='part'">
          <xsl:value-of select="concat('-',.,'-')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:apply-templates select="tei:pron"/>
    <xsl:if test="$paren">
      <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="tei:form"/>
    <xsl:if test="following-sibling::tei:form and following-sibling::tei:form[1][not(@type='infl')]">
      <xsl:text>, </xsl:text>
      <!-- cosmetics: no comma before parens  -->
    </xsl:if>
  </xsl:template>

  <!-- can't see when this template may be active; see above for enhancement (pref, suff), if necessary -->
  <xsl:template match="tei:orth">
    <xsl:value-of select="."/>
    <xsl:if test="position() != last()">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="tei:pron"/>
  </xsl:template>

  <xsl:template match="tei:pron">
    <xsl:value-of select="concat(' /',.,'/')"/>
    <!--<xsl:text> /</xsl:text><xsl:apply-templates/><xsl:text>/</xsl:text>-->
  </xsl:template>

  <!-- allow for empty <pos/>; make it a condition for the presence of angled brackets, too 
  the weird "(self::gramGrp or count(tei:pos/text())" 
      means "you're either P4 or <pos> in P5 is non-empty"
-->
  <xsl:template match="tei:gramGrp">
    <xsl:variable name="bracket"
      select="count(ancestor::tei:gramGrp)=0 and (count(tei:pos/text()) or count(tei:*[local-name() != 'pos']))"
    />
    <xsl:if test="$bracket">
      <xsl:text> &lt;</xsl:text>
    </xsl:if>
    <xsl:for-each
      select="tei:pos[text()] | tei:subc | tei:num | tei:gen | tei:gramGrp | tei:iType | tei:gram">
      <xsl:apply-templates select="."/>
      <xsl:if test="position()!=last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="$bracket">
      <xsl:text>></xsl:text>
    </xsl:if>

    <!-- <xr> elements are not allowed inside <form> or <gramGrp>, so reach out and grab them... -->
    <xsl:if
      test="count(preceding-sibling::tei:xr[@type='plural-form' or @type='imp-form' or
                    @type='past-form' or @type='infl-form'])">
      <xsl:text> </xsl:text>
      <xsl:apply-templates
        select="preceding-sibling::tei:xr[@type='plural-form' or @type='imp-form' or
                                   @type='past-form' or @type='infl-form']"
      />
    </xsl:if>
    <!-- horribly project-specific, will be overridden by project-specific imports later on; 
      OTOH, we might make this a project feature, too, if there is a need -->
    <xsl:if test="preceding-sibling::tei:form/@type='N'">
      <xsl:text> [sg=pl]</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:gram[@type='cl-agr']">
    <xsl:value-of select="concat('agr: ',.)"/>
  </xsl:template>

  <xsl:template match="tei:sense">
    <xsl:variable name="prec_senses">
      <xsl:choose>
        <xsl:when test="not(preceding-sibling::tei:sense)">0</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="count(preceding-sibling::tei:sense)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="pref">
      <xsl:choose>
        <xsl:when test="@n">
          <xsl:value-of select="concat(@n,'. ')"/>
        </xsl:when>
        <xsl:when test="number($prec_senses) > 0 or following-sibling::tei:sense">
          <xsl:value-of select="concat(position(),'. ')"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="number($prec_senses) > 0">
      <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:value-of select="concat(' ',$pref)"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tei:cit">
    <xsl:if test="@type='trans' and preceding-sibling::tei:cit[@type='trans']"><xsl:text>; </xsl:text></xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tei:quote">
    <xsl:choose>
      <xsl:when test="parent::tei:cit[@type='dicteg']">
        <xsl:value-of select="concat('&quot;',.,'&quot;')"/>
      </xsl:when>
      <xsl:when test="parent::tei:cit[@type='trans'][parent::tei:cit[@type='dicteg']]">
        <xsl:value-of select="concat(' - ',.,'&#xa;')"/>
      </xsl:when>
      <xsl:when test="preceding-sibling::tei:quote"> <!-- parent::tei:cit[@type='trans'] and  -->
        <xsl:value-of select="', '"/>
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="tei:usg[@type]">
    <!-- insert spaces -->
    <xsl:if test="preceding-sibling::tei:cit[@type='trans'] or preceding-sibling::tei:quote">
      <xsl:text> </xsl:text> <!-- space if after a sibling -->
    </xsl:if>

    <xsl:text>[</xsl:text>
    <xsl:value-of select="."/>
    <xsl:if test="not(self::node()[contains(text(), ' ')])">
      <xsl:text>.</xsl:text> <!-- if space in value, then no abbrev. anymore, skip "." -->
    </xsl:if>
    <xsl:text>]</xsl:text>

    <!-- if another sibling afterwards, insert space -->
    <xsl:if test="following-sibling::*">
        <xsl:text> </xsl:text> <!-- space if followed by more stuff -->
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:def">
    <xsl:variable name="stuff">
      <xsl:apply-templates select="*|text()"/>
    </xsl:variable>
    <!-- first question: am I abused? Do I hold a translation equivalent 
    within a <sense>, or am I a real definition within a <cit>? -->
    <xsl:choose>
      <xsl:when test="parent::tei:sense">
        <xsl:variable name="separator">
          <xsl:choose>
            <xsl:when test="preceding-sibling::tei:def">
              <xsl:value-of select="'; '"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="''"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($separator,$stuff)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="format">
          <xsl:with-param name="txt" select="normalize-space($stuff)"/>
          <xsl:with-param name="width" select="75"/>
          <xsl:with-param name="start" select="4"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:xr">
    <xsl:choose>
      <xsl:when test="count(@rend) and @rend='as-is'">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="not(@type) or @type='cf'">
            <xsl:text>&#xa;   See also: </xsl:text>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>&#xa;</xsl:text>
          </xsl:when>
          <xsl:when test="@type='syn'">
            <xsl:text>&#xa;   </xsl:text>
            <xsl:choose>
              <xsl:when test="count(tei:ref) &gt; 1">
                <xsl:text>Synonyms: </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>Synonym: </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>&#xa;</xsl:text>
          </xsl:when>
          <xsl:when test="@type='ant'">
            <xsl:text>&#xa;   </xsl:text>
            <xsl:choose>
              <xsl:when test="count(tei:ref) &gt; 1">
                <xsl:text>Antonyms: </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>Antonym: </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>&#xa;</xsl:text>
          </xsl:when>
          <xsl:when test="@type='infl-base'">
            <!-- inflectional base -->
            <xsl:text>&#xa; Inflection of: </xsl:text>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>&#xa;</xsl:text>
          </xsl:when>
          <xsl:when test="@type='deriv-base'">
            <!-- derivational/compound base -->
            <xsl:text>&#xa; Derived from: </xsl:text>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>&#xa;</xsl:text>
          </xsl:when>
          <!-- the <xr>s below are positioned inline -->
          <xsl:when test="@type='imp-form'">
            <!-- imperative -->
            <xsl:text>(imp: </xsl:text>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:when test="@type='plural-form'">
            <!-- plural -->
            <xsl:text>(pl: </xsl:text>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:when test="@type='past-form'">
            <!-- past -->
            <xsl:text>(past: </xsl:text>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:when test="@type='infl-form'">
            <!-- general inflections, e.g. past/pprt/fut -->
            <xsl:text>(</xsl:text>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <!-- unknown type: print the value and set it on a separate line -->
            <xsl:text>&#xa; </xsl:text>
            <xsl:value-of select="concat(@type,': ')"/>
            <xsl:apply-templates select="tei:ref"/>
            <xsl:text>&#xa;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:ref">
    <xsl:if test="preceding-sibling::*[1][self::tei:ref]">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="ancestor::tei:teiHeader or ancestor::tei:front">
        <xsl:value-of select="concat(.,' [',@target,']')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('{',.,'}')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:entry//tei:p">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tei:note[@type='editor']" priority="1"/>

  <xsl:template match="tei:entry//tei:note">
    <xsl:variable name="stuff">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:variable name="spc">
      <xsl:choose>
        <xsl:when test="(count(preceding-sibling::node())=0) or @rend='noindent'">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="' '"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="count(@*)=0">
        <xsl:value-of select="concat('&#xa;         Note: ',$stuff)"/>
      </xsl:when>
      <xsl:when test="@resp='translator'">
        <xsl:text>&#xa;         Entry edited by: </xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&#xa;</xsl:text>
      </xsl:when>
      <!-- a subset of values from the TEI Guidelines -->
      <xsl:when
        test="@type='lbl' or @type='dom' or @type='obj' or @type='subj' or @type='hint' or @type='num' or @type='geo' or @type='syn' or @type='colloc' or @type='hint'">
        <xsl:value-of select="concat($spc,'(',.,')')"/>
      </xsl:when>
      <xsl:when test="@type='gram'">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="format">
          <xsl:with-param name="txt" select="concat(' (',normalize-space($stuff),')')"/>
          <!--          select="concat(' Note (gram.): ',normalize-space($stuff))"-->
          <xsl:with-param name="width" select="75"/>
          <xsl:with-param name="start" select="1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@type='usage'">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="format">
          <xsl:with-param name="txt" select="concat(' (',normalize-space($stuff),')')"/>
          <!--          select="concat(' Usage: ',normalize-space($stuff))"-->
          <xsl:with-param name="width" select="75"/>
          <xsl:with-param name="start" select="1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@type='def'">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="format">
          <!--<xsl:with-param name="txt" select="concat(' Def.: ',normalize-space())"/>-->
          <xsl:with-param name="txt" select="concat(' ',normalize-space($stuff))"/>
          <xsl:with-param name="width" select="75"/>
          <xsl:with-param name="start" select="1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($spc,'(',$stuff,')')"/>
        <xsl:text>&#xa;</xsl:text>
      </xsl:otherwise>
      <!--<xsl:when test="text()">
        <xsl:text>&#xa;         Note: </xsl:text>
        <xsl:value-of select="text()"/>
      </xsl:when>-->
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:q">
    <xsl:value-of select="concat('&quot;',.,'&quot;')"/>
  </xsl:template>

</xsl:stylesheet>

