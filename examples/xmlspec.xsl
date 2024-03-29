<?xml version="1.0" encoding="ISO-8859-1" ?>
<!-- @(#)xslspec.xsl 1.3 99/01/11 SMI; Style Sheet for the XML and XSL Recommendations and Working Drafts; written by Eduardo Gutentag -->
<!-- $Id: xmlspec.xsl,v 1.28 1999/11/15 12:58:16 jjc Exp $ Hacked by James Clark -->
<!DOCTYPE xsl:stylesheet [
<!ENTITY copy   "&#169;">
<!ENTITY nbsp   "&#160;">
]>
<!-- XSL Style sheet, DTD omitted -->
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="html" doctype-public="-//W3C//DTD HTML 4.0 Transitional//EN"/>

<xsl:param name="w3">http://www.w3.org/</xsl:param>
<!--
+++++++++++++++++++++++++

Inclusions

+++++++++++++++++++++++++
-->

<xsl:template match="spec" mode="css">
<xsl:text>code { font-family: monospace }</xsl:text>
</xsl:template>

<!--
*******************************************************************

Basic framework to format W3C specs (as in the XML spec)

*******************************************************************
-->
	<xsl:template match="spec">
		<html>
		<head>
		<title>
		<xsl:value-of select="header/title"/>
		</title>
		<link rel="stylesheet" type="text/css"
                      href="{$w3}StyleSheets/TR/W3C-{substring-before(header/w3c-designation,'-')}"/>
		<!-- This stops Netscape 4.5 from messing up. -->
		<style type="text/css">
                <xsl:apply-templates select="." mode="css"/>
                </style>
		</head>
		<body>
			<xsl:apply-templates/>
		</body>
		</html>
	</xsl:template>
<!-- 
*******************************************************************

Prologue

*******************************************************************
-->

        <xsl:template match="header">
                <div class="head">
                        <a href="http://www.w3.org/">
			  <img src="{$w3}Icons/WWW/w3c_home"
			       alt="W3C" height="48" width="72"/>
                        </a>
			<h1>
                            <xsl:value-of select="title"/>
			    <br/>
                            <xsl:value-of select="version"/>
                        </h1>
                        <h2>
				<xsl:value-of select="w3c-doctype"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="pubdate/day"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="pubdate/month"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="pubdate/year"/>
			</h2>
                        <dl>
                        	<xsl:apply-templates select="publoc"/>
		                <xsl:apply-templates select="latestloc"/>
                		<xsl:apply-templates select="prevlocs"/>
                		<xsl:apply-templates select="authlist"/>
                	</dl>
                	<xsl:call-template name="copyright"/>
                	<hr title="Separator for header"/>
                </div>
		<xsl:apply-templates select="abstract"/>
		<xsl:apply-templates select="status"/>
        </xsl:template>

	<xsl:template match="publoc">
		<dt>This version:</dt>
	        <dd><xsl:apply-templates/></dd>
	</xsl:template>
	<xsl:template match="publoc/loc|latestloc/loc|prevlocs/loc">
			<a href="{@href}"><xsl:apply-templates/></a>
			<br/>
	</xsl:template>
	<xsl:template match="latestloc">
		<dt>Latest version:</dt>
	        <dd><xsl:apply-templates/></dd>
	</xsl:template>

	<xsl:template match="prevlocs">
		<dt>
                  <xsl:text>Previous version</xsl:text>
                  <xsl:if test="count(loc)>1">s</xsl:if>
		  <xsl:text>:</xsl:text>
                </dt>
                <dd><xsl:apply-templates/></dd>
	</xsl:template>
	<xsl:template match="authlist">
		<dt>
                  <xsl:text>Editor</xsl:text>
                  <xsl:if test="count(author)>1">s</xsl:if>
		  <xsl:text>:</xsl:text>
                </dt>
		<dd> <xsl:apply-templates/></dd>
	</xsl:template>
	<xsl:template match="author">
		<xsl:apply-templates/>
		<br/>
	</xsl:template>

	<xsl:template match="author/name">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="author/affiliation">
		<xsl:text> (</xsl:text>
			<xsl:apply-templates/>
		<xsl:text>) </xsl:text>
	</xsl:template>

	<xsl:template match="author/email">
		<a href="{@href}">
			<xsl:text>&lt;</xsl:text>
				<xsl:apply-templates/>
			<xsl:text>&gt;</xsl:text>
		</a>
	</xsl:template>

	<xsl:template match="abstract">
		<h2><a name="abstract">Abstract</a></h2>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="status">
		<h2><a name="status">Status of this document</a></h2>
		<xsl:apply-templates/>
	</xsl:template>
		
<!-- 
*******************************************************************

Real body work

*******************************************************************
-->

	<xsl:template match="body">
		<h2><a name="contents">Table of contents</a></h2>
		<xsl:call-template name="toc"/>
		<hr/>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="back">
	<hr title="Separator from footer"/>
	<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="div1/head|inform-div1/head">
		<h2><xsl:call-template name="head"/></h2>
	</xsl:template>

	<xsl:template match="div2/head">
		<h3><xsl:call-template name="head"/></h3>
	</xsl:template>

	<xsl:template match="div3/head">
		<h4><xsl:call-template name="head"/></h4>
	</xsl:template>

	<xsl:template match="div4/head">
		<h5><xsl:call-template name="head"/></h5>
	</xsl:template>

        <xsl:template name="head">
                <xsl:for-each select="..">
			<xsl:call-template name="insertID"/>
                	<xsl:apply-templates select="." mode="number"/>
                </xsl:for-each>
		<xsl:apply-templates/>
                <xsl:call-template name="inform"/>
        </xsl:template>

<!-- 
*******************************************************************

Blocks

*******************************************************************
-->
	<xsl:template match="item/p" priority="1">
	<p>
		<xsl:apply-templates/>
	</p>
	</xsl:template>

	<xsl:template match="p">
		<p>
			<xsl:apply-templates/>
		</p>
	</xsl:template>


	<xsl:template match="eg">
		<pre>
                        <xsl:if test="@role='error'">
                            <xsl:attribute name="style">color: red</xsl:attribute>
                        </xsl:if>
			<xsl:apply-templates/>
		</pre>
	</xsl:template>

	<xsl:template match="htable">
		<table border="{@border}"
			   cellpadding="{@cellpadding}"
			   align="{@align}">
			<xsl:apply-templates/>
		</table>
	</xsl:template>

	<xsl:template match="htbody">
		<tbody>
			<xsl:apply-templates/>
		</tbody>
	</xsl:template>

	<xsl:template match="tr">
		<tr align="{@align}"
			valign="{@valign}">
			<xsl:apply-templates/>
		</tr>
	</xsl:template>

	<xsl:template match="td">
		<td bgcolor="{@bgcolor}"
			rowspan="{@rowspan}"
			colspan="{@colspan}"
			align="{@align}"
			valign="{@valign}">
			<xsl:apply-templates/>
		</td>
	</xsl:template>

	<xsl:template match="ednote">
		<blockquote>
		<p><b>Ed. Note: </b><xsl:apply-templates/></p>
		</blockquote>
	</xsl:template>

	<xsl:template match="edtext">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="issue">
		<xsl:call-template name="insertID"/>
		<blockquote>
			<p>
			<b>Issue (<xsl:value-of select="substring-after(@id,'-')"/>): </b>
			<xsl:apply-templates/>
			</p>
		</blockquote>
	</xsl:template>


	<xsl:template match="note">
	<blockquote>
		<b>NOTE: </b>
		<xsl:apply-templates/>
	</blockquote>
	</xsl:template>

	<xsl:template match="issue/p|note/p">
	<xsl:apply-templates/>
	</xsl:template>
<!-- 
*******************************************************************

Productions

*******************************************************************
-->
	<xsl:template match="scrap">
                <xsl:if test="string(head)">
		  <h5><xsl:value-of select="head"/></h5>
                </xsl:if>
		<table class="scrap">
		<tbody>
		<xsl:apply-templates select="prodgroup|prod"/>
		</tbody>
		</table>
	</xsl:template>


	<xsl:template match="prod">
	    <!-- select elements that start a row -->
	    <xsl:apply-templates select="
*[self::lhs
  or ((self::vc or self::wfc or self::com)
      and not(preceding-sibling::*[1][self::rhs]))
  or (self::rhs
      and not(preceding-sibling::*[1][self::lhs]))]
"/>
	</xsl:template>

	<xsl:template match="lhs">
		<tr valign="baseline">
		<td><a name="{../@id}"/>
		<xsl:number from="body" level="any" format="[1]&nbsp;&nbsp;&nbsp;"/>
		</td>
		<td><xsl:apply-templates/></td>
		<td><xsl:text>&nbsp;&nbsp;&nbsp;::=&nbsp;&nbsp;&nbsp;</xsl:text></td>
		<xsl:for-each select="following-sibling::*[1]">
		  <td><xsl:apply-templates mode="cell" select="."/></td>
		  <td><xsl:apply-templates mode="cell" select="following-sibling::*[1][self::vc or self::wfc or self::com]"/></td>
		</xsl:for-each>
		</tr>
	</xsl:template>

	<xsl:template match="rhs">
		<tr valign="baseline">
                  <td></td>
                  <td></td>
		  <td></td>
		  <td><xsl:apply-templates mode="cell" select="."/></td>
		  <td><xsl:apply-templates mode="cell" select="following-sibling::*[1][self::vc or self::wfc or self::com]"/></td>
		</tr>
	</xsl:template>

	<xsl:template match="vc|wfc|com">
		<tr valign="baseline">
                  <td></td>
                  <td></td>
		<td></td>
		<td></td>
		<td><xsl:apply-templates mode="cell" select="."/></td>
		</tr>
	</xsl:template>


	<xsl:template match="prodgroup">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="com" mode="cell">
		<xsl:text>/*</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>*/</xsl:text>
	</xsl:template>

	<xsl:template match="rhs" mode="cell">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="vc" mode="cell">
		<xsl:text>[&nbsp;VC:&nbsp;</xsl:text>
	<a href="#{@def}">
		<xsl:value-of select="id(@def)/head"/>
	</a>
		<xsl:text>&nbsp;]</xsl:text>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="wfc" mode="cell">
		<xsl:text>[&nbsp;WFC:&nbsp;</xsl:text>
	<a href="#{@def}">
		<xsl:value-of select="id(@def)/head"/>
	</a>
		<xsl:text>&nbsp;]</xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
<!-- 
*******************************************************************

References

*******************************************************************
-->
	<xsl:template match="p/loc" priority="1">
		<a href="{@href}"><xsl:apply-templates/></a>
	</xsl:template>

	<xsl:template match="publoc/loc|latestloc/loc|prevlocs/loc">
		<a href="{@href}"><xsl:apply-templates/></a>
		<br/>
	</xsl:template>

	<xsl:template match="loc">
		<a href="{@href}"><xsl:apply-templates/></a>
	</xsl:template>


	<xsl:template match="bibref">
		<a href="#{@ref}">
		<xsl:text>[</xsl:text>
		<xsl:value-of select="id(@ref)/@key"/>
		<xsl:apply-templates/>
		<xsl:text>]</xsl:text>
		</a>
	</xsl:template>

	<xsl:template match="specref">
		<a href="#{@ref}">
		<xsl:text>[</xsl:text>
		<b>
                <xsl:for-each select="id(@ref)/head">
                        <xsl:apply-templates select=".." mode="number"/>
                        <xsl:apply-templates/>
		</xsl:for-each>
		</b>
		<xsl:apply-templates/>
		<xsl:text>]</xsl:text>
		</a>
	</xsl:template>
	<xsl:template match="xspecref|xtermref">
		<a href="{@href}">
		<xsl:apply-templates/>
		</a>
	</xsl:template>
	<xsl:template match="termref">
		<a href="#{@def}">
		<xsl:apply-templates/>
		</a>
	</xsl:template>

	<xsl:template match="titleref">
		<a href="#{@href}">
		<xsl:apply-templates/>
		</a>
	</xsl:template>

	<xsl:template match="termdef">
		<a name="{@id}">
		</a>
			<xsl:apply-templates/>
	</xsl:template>


	<xsl:template match="vcnote">
		<a name="{@id}"></a>
		<p><b>Validity Constraint: <xsl:value-of select="head"/></b></p>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="wfcnote">
		<a name="{@id}"></a>
		<p><b>Well Formedness Constraint: <xsl:value-of select="head"/></b></p>
		<xsl:apply-templates/>
	</xsl:template>

<!-- 
*******************************************************************

Inlines

*******************************************************************
-->
	<xsl:template match="termdef">
		<a name="{@id}">
		</a>
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="term">
		<b><xsl:apply-templates/></b>
	</xsl:template>

	<xsl:template match="orglist/member[1]" priority="2">
		<xsl:apply-templates select="*"/>
	</xsl:template>

	<xsl:template match="orglist/member">
	        <xsl:text>; </xsl:text>
		<xsl:apply-templates select="*"/>
	</xsl:template>
	
	<xsl:template match="orglist/member/affiliation">
                 <xsl:text>, </xsl:text>
                 <xsl:apply-templates/>
        </xsl:template>
	<xsl:template match="orglist/member/role">
			<xsl:text> (</xsl:text>
			<xsl:apply-templates/>
			<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template match="code">
		<code>
			<xsl:apply-templates/>
		</code>
	</xsl:template>

	<xsl:template match="emph">
		<i>
			<xsl:apply-templates/>
		</i>
	</xsl:template>
<!-- 
*******************************************************************

Lists

*******************************************************************
-->
	<xsl:template match="blist">
	<dl>
		<xsl:apply-templates/>
	</dl>
	</xsl:template>

	<xsl:template match="slist">
	<ul>
		<xsl:apply-templates/>
	</ul>
	</xsl:template>
	<xsl:template match="sitem">
	<li>
		<xsl:apply-templates/>
	</li>
	</xsl:template>

	<xsl:template match="blist/bibl">
		<dt>
			<a name="{@id}">
			<xsl:value-of select="@key"/>
			</a>
		</dt>
		<dd>
			<xsl:apply-templates/>
		</dd>
	</xsl:template>

	<xsl:template match="olist">
	<ol>
		<xsl:apply-templates/>
	</ol>
	</xsl:template>

	<xsl:template match="ulist">
	<!--
	<ul type="circle">
	-->
	<ul>
		<xsl:apply-templates/>
	</ul>
	</xsl:template>

	<xsl:template match="glist">
		<dl>
			<xsl:apply-templates/>
		</dl>
	</xsl:template>

	<xsl:template match="item">
	<li>
		<xsl:apply-templates/>
	</li>
	</xsl:template>

	<xsl:template match="label">
	<dt>
		<b><xsl:apply-templates/></b>
	</dt>
	</xsl:template>

	<xsl:template match="def">
	<dd>
		<xsl:apply-templates/>
	</dd>
	</xsl:template>

	<xsl:template match="orglist">
		<xsl:apply-templates select="*"/>
	</xsl:template>


	<xsl:template match="olist">
	<ol>
		<xsl:apply-templates/>
	</ol>
	</xsl:template>


<!-- 
*******************************************************************

Empty templates

*******************************************************************
-->
	<xsl:template match="w3c-designation">
	</xsl:template>

	<xsl:template match="w3c-doctype">
	</xsl:template>

	<xsl:template match="header/pubdate">
	</xsl:template>


	<xsl:template match="spec/header/title">
	</xsl:template>

	<xsl:template match="revisiondesc">
	</xsl:template>
	
	<xsl:template match="pubstmt">
	</xsl:template>

	<xsl:template match="sourcedesc">
	</xsl:template>

	<xsl:template match="langusage">
	</xsl:template>

	<xsl:template match="version">
	</xsl:template>
<!-- 
*******************************************************************

Macros


*******************************************************************
-->

	<xsl:template name="copyright">
	<p class="copyright">
		<a href="http://www.w3.org/Consortium/Legal/ipr-notice.html#Copyright">
		Copyright</a> &nbsp;&copy;&nbsp; 1999 <a href="http://www.w3.org">W3C</a>
		(<a href="http://www.lcs.mit.edu">MIT</a>,
		<a href="http://www.inria.fr/">INRIA</a>,
		<a href="http://www.keio.ac.jp/">Keio</a>), All Rights Reserved. W3C
		<a href="http://www.w3.org/Consortium/Legal/ipr-notice.html#Legal_Disclaimer">liability</a>,
		<a href="http://www.w3.org/Consortium/Legal/ipr-notice.html#W3C_Trademarks">trademark</a>,
		<a href="http://www.w3.org/Consortium/Legal/copyright-documents.html">document use</a> and
		<a href="http://www.w3.org/Consortium/Legal/copyright-software.html">software licensing</a> rules apply.
	</p>
	</xsl:template>

	<xsl:template name="toc">
		<xsl:for-each select="/spec/body/div1">
				<xsl:call-template name="makeref"/>
				<br/>

				<xsl:for-each select="div2">
					<xsl:text>&nbsp;&nbsp;&nbsp;&nbsp;</xsl:text>
					<xsl:call-template name="makeref"/>
					<br/>
						<xsl:for-each select="div3">
							<xsl:text>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</xsl:text>
								<xsl:call-template name="makeref"/>
							<br/>
						</xsl:for-each>
				</xsl:for-each>
		</xsl:for-each>

		<h3>Appendices</h3>

		<xsl:for-each select="/spec/back/div1 | /spec/back/inform-div1">
				<xsl:call-template name="makeref"/>
				<br/>

				<xsl:for-each select="div2">
						<xsl:text>&nbsp;&nbsp;&nbsp;&nbsp;</xsl:text>
						<xsl:call-template name="makeref"/>
						<br/>

						<xsl:for-each select="div3">
								<xsl:text>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</xsl:text>
								<xsl:call-template name="makeref"/>
								<br/>
						</xsl:for-each>
				</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="insertID">
		<xsl:choose>
			<xsl:when test="@id">
				<a name="{@id}"/>
			</xsl:when>
			<xsl:otherwise>
				<a name="section-{translate(head,' ','-')}"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="makeref">
                <xsl:apply-templates select="." mode="number"/>
		<xsl:choose>
			<xsl:when test="@id">
				<a href="#{@id}">
					<xsl:value-of select="head"/>
				</a>
			</xsl:when>
			<xsl:otherwise>
				<a href="#section-{translate(head,' ','-')}">
					<xsl:value-of select="head"/>
				</a>
			</xsl:otherwise>
		</xsl:choose>
                <xsl:for-each select="head">
                  <xsl:call-template name="inform"/>
                </xsl:for-each>
	</xsl:template>

        <xsl:template name="inform">
           <xsl:if test="parent::inform-div1">
              <xsl:text> (Non-Normative)</xsl:text>
           </xsl:if>
        </xsl:template>

	<xsl:template match="nt">
		<a href="#{@def}"><xsl:apply-templates/></a>
        </xsl:template>

	<xsl:template match="xnt">
		<a href="{@href}"><xsl:apply-templates/></a>
        </xsl:template>

	<xsl:template match="quote">
		<xsl:text>"</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
	<xsl:template mode="number" match="back//*">
           <xsl:number level="multiple"
                       count="inform-div1|div1|div2|div3|div4"
                       format="A.1 "/>
        </xsl:template>
	<xsl:template mode="number" match="*">
           <xsl:number level="multiple"
                       count="inform-div1|div1|div2|div3|div4"
                       format="1.1 "/>
        </xsl:template>

</xsl:stylesheet>
