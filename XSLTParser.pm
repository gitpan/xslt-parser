################################################################################
#
# Perl module: XSLTParser
#
# By Geert Josten, gjosten@sci.kun.nl
# and Egon Willighagen, egonw@sci.kun.nl
#
################################################################################

######################################################################
package XSLTParser;
######################################################################
use strict;
use XML::DOM;

BEGIN {
  require XML::DOM;
  use Exporter ();
  use vars qw( $VERSION @ISA @EXPORT);

  do "version.h";

  @ISA         = qw( Exporter );
  @EXPORT      = qw( &new &openproject &evaluate_xsl &print_xsl );

  use vars qw ( $_indent );
  $_indent = "";
  $_indent = 0;
}

sub new {
  my ($class) = @_;

  return bless {}, $class;  
}

sub openproject {
  my ($self, $xmlfile, $xslfile) = @_;

  $XSLT::DOMparser = new XML::DOM::Parser;
  $XSLT::xsl = $XSLT::DOMparser->parsefile ("$xslfile");
  $XSLT::xml = $XSLT::DOMparser->parsefile ("$xmlfile");
  $XSLT::result = new XML::DOM::Document;
}

sub evaluate_xsl {
  my ($self) = @_;

  $self->_evaluate_contents (
    $XSLT::xsl, # current XSL node, the root
    $XSLT::xml, # current XML node, the root
    ''          # current XML selection path, the root
  );
}

sub print_xsl {
  my ($self, $fh) = @_;

  $XSLT::outputstring = $XSLT::xsl->toString;

  $XSLT::outputstring =~ s/\<xsl.*?\>//g;           # Strip xsl opening tags
  $XSLT::outputstring =~ s/\<\/xsl.*?\>//g;         # Strip xsl closing tags
  $XSLT::outputstring =~ s/\n\s*\n(\s*)\n/\n$1\n/g; # Substitute multiple empty lines by one
  $XSLT::outputstring =~ s/\/\>/ \/\>/g;            # Insert a space before all />

  if ($fh) {
    print $fh $XSLT::outputstring;
  } else {
    print $XSLT::outputstring;
  }
}

sub _evaluate_contents {
  my $self = shift;
  my $current_xsl_node = shift;
  my $current_xml_node = shift;
  my $current_xml_selection_path = shift;

  print " "x$_indent, "path: \"$current_xml_selection_path\"$/" if $XSLT::debug;
  $_indent += 2;
  if ($current_xsl_node->hasChildNodes) {
    my $xsl_children = $current_xsl_node->getElementsByTagName('*','');
    
    foreach my $xsl_child (@$xsl_children) {
      $self->_examine_child ($xsl_child, $current_xml_node, $current_xml_selection_path);
    }
  }
  $_indent -= 2;
  print " "x$_indent, "path: \"$current_xml_selection_path\"$/" if $XSLT::debug;
}

sub _examine_child {
  my $self = shift;
  my $current_xsl_child = shift;
  my $current_xml_node = shift;
  my $current_xml_selection_path = shift;
  
    $current_xsl_child->normalize();
    
    print " "x$_indent, "<", $current_xsl_child->getTagName, ">", $/ if $XSLT::debug;

    if ($current_xsl_child->getTagName =~ /^xsl:/i) {

        if ($current_xsl_child->getTagName =~ /^xsl:stylesheet/i
        || $current_xsl_child->getTagName =~ /^xsl:template/i
        || $current_xsl_child->getTagName =~ /^xsl:sub-template/i) {

            # extend the base reference of the xml tree and recurse
            my $xml_path_extension = $current_xsl_child->getAttribute('select');
            my $curr_xml_node = $self->parse_xml_selection ($current_xml_node,
                                    $current_xml_selection_path, $xml_path_extension);
            if ($curr_xml_node) {
              if (!$xml_path_extension || $xml_path_extension eq "/") {
                $self->_evaluate_contents ($current_xsl_child, $curr_xml_node,
                                       "$current_xml_selection_path");
              } else {
                $self->_evaluate_contents ($current_xsl_child, $curr_xml_node,
                                       "$current_xml_selection_path/$xml_path_extension");
              }
            }

        } elsif ($current_xsl_child->getTagName =~ /^xsl:include/i) {

            # get include file name and look if exists
            my $include_file = $current_xsl_child->getAttribute('select');
            if (! (-f $include_file)) {
              die "Error: include $include_file can not be read$/";
            }

            # parse file and insert tree into xsl tree
            my $include_xsl = $XSLT::DOMparser->parsefile ($include_file);
            my $xsl_append_tree = $include_xsl->getFirstChild();
            
            if ($xsl_append_tree) {
              $xsl_append_tree->setOwnerDocument ($XSLT::xsl);
              $current_xsl_child->appendChild ($xsl_append_tree);
            }

            # recurse into inserted tree
            $self->_evaluate_contents ($current_xsl_child, $current_xml_node,
                                                $current_xml_selection_path);

        } elsif ($current_xsl_child->getTagName =~ /^xsl:value-of/i) {

            # get element from xml tree
            my $xml_selection = $current_xsl_child->getAttribute('select');
            my $xml_item = $self->parse_xml_selection ($current_xml_node, $current_xml_selection_path,
                                                                   $xml_selection);

            if ($xml_item) {
              if ($xml_item->isTextNode) {
                $current_xsl_child->appendChild($xml_item);
              } elsif ($xml_item->hasChildNodes) {
                $current_xsl_child->appendChild ($xml_item->getFirstChild);
              }
            }

        } elsif ($current_xsl_child->getTagName =~ /^xsl:for-each/i) {

            # copy xsl sub tree
            my $xsl_sub_tree_orig = $current_xsl_child->cloneNode ('deep');
            my $xsl_sub_tree;

            # delete from xsl
            foreach my $child ($current_xsl_child->getChildNodes) {
              $current_xsl_child->removeChild ($child);
            }

            # select appropriate xml part
            my $xml_selection = $current_xsl_child->getAttribute('select');
            my $xml_parent = $self->parse_xml_selection ($current_xml_node, $current_xml_selection_path, "");

            if ($xml_parent && $xml_parent->hasChildNodes) {
              # search xml for matches
              my $child_nodes = $xml_parent->getElementsByTagName($xml_selection,'');

              # look at each child
              my $count = 0;
              foreach my $node (@$child_nodes) {

                # copy sub tree to evaluate it for this match
                $xsl_sub_tree = $xsl_sub_tree_orig->cloneNode ('deep');

                # recurse for this match
                my $curr_xml_node = $self->parse_xml_selection ($current_xml_node,
                  $current_xml_selection_path, join ("", $xml_selection,'[',$count,']'));
                $self->_evaluate_contents ($xsl_sub_tree, $curr_xml_node,
                  join ("", $current_xml_selection_path,'/',$xml_selection,'[',$count,']'));

                # and append to xsl tree
                $current_xsl_child->appendChild ($xsl_sub_tree);
                $count++;
              }
            }

        } elsif ($current_xsl_child->getTagName =~ /^xsl:choose/i) {

            my $not_done = "True";
            my $when_nodes = $current_xsl_child->getElementsByTagName ('xsl:when', '');

            # test all when cases
            for (my $i = 0; $i < $when_nodes->getLength(); $i++) {
              my $node = $when_nodes->item($i);
              if ($not_done) {
                my $xml_selection = $node->getAttribute('test');
	        my ($sec_item, $sec_attr, $sec_value) = parse_xsl_select($current_xml_node, $xml_selection);
                my $xml_item = $self->parse_xml_selection ($current_xml_node, $current_xml_selection_path,
                                                                   $xml_selection);

                # insert if when tests okay
                if (($xml_item) && ($sec_attr)) {
	          # attr must be tested 
		  print " "x$_indent, "  trying to get attribute\n" if $XSLT::debug;
		  my $attr_value = $xml_item->getAttribute($sec_attr);
		  if ($attr_value ne $sec_value) {
                    $current_xsl_child->removeChild($node);
                  } else {
                    $not_done = ""; # False
                  }
                # else remove
                } else {
                  $current_xsl_child->removeChild($node);
                }
              # else remove
              } else {
                $current_xsl_child->removeChild($node);
              }
            }

            # or get the default case if available
            my $otherwise_nodes = $current_xsl_child->getElementsByTagName ("xsl:otherwise", "notdeep");
            my $n = $otherwise_nodes->getLength();
            for (my $i = 0; $i < $n; $i++) {
              my $node = $otherwise_nodes->item($i);
              if ($not_done) {
                my $xml_selection = $node->getAttribute('test');
	        my ($sec_item, $sec_attr, $sec_value) = parse_xsl_select($current_xml_node, $xml_selection);
                my $xml_item = $self->parse_xml_selection ($current_xml_node, $current_xml_selection_path,
                                                               $xml_selection);

                # insert if when tests okay
                if (($xml_item) && ($sec_attr)) {
	          # attr must be tested 
		  print " "x$_indent, "  trying to get attribute\n" if $XSLT::debug;
		  my $attr_value = $xml_item->getAttribute($sec_attr);
		  if ($attr_value ne $sec_value) {
                    $current_xsl_child->removeChild($node);
                  } else {
                    $not_done = ""; # False
                  }
                # else remove
                } else {
                  $current_xsl_child->removeChild($node);
                }
              # else remove
              } else {
                $current_xsl_child->removeChild($node);
              }
            }

            # recurse into sub tree
            $self->_evaluate_contents ($current_xsl_child, $current_xml_node, $current_xml_selection_path);

        } elsif ($current_xsl_child->getTagName =~ /^xsl:when/i) {

            my $xml_selection = $current_xsl_child->getAttribute('test');
	    my ($sec_item, $sec_attr, $sec_value) = parse_xsl_select($current_xml_node, $xml_selection);
            my $xml_item = $self->parse_xml_selection ($current_xml_node, $current_xml_selection_path, $sec_item);

            # remove if not tests okay
            if (!$xml_item) {
              #$node->getParentNode()->removeChild($node);
              while ($current_xsl_child->hasChildNodes) {
                $current_xsl_child->removeChild ($current_xsl_child->getLastChild);
              }
            } else {
	      #node found
	      if ($sec_attr) {
	        # attr must be tested 
		print " "x$_indent, "  trying to get attribute\n" if $XSLT::debug;
		my $attr_value = $xml_item->getAttribute($sec_attr);
		if ($attr_value ne $sec_value) {
        	  while ($current_xsl_child->hasChildNodes) {
                    $current_xsl_child->removeChild ($current_xsl_child->getLastChild);
        	  }
		}
              }
	    }

            # recurse into sub tree
            $self->_evaluate_contents ($current_xsl_child, $current_xml_node, $current_xml_selection_path);

        } elsif ($current_xsl_child->getTagName =~ /^xsl:processing-instruction/i) {
 
            my $new_PI = $XSLT::xsl->createProcessingInstruction("xsl", $current_xsl_child->getFirstChild->getNodeValue);
 
            if ($new_PI) {
              $current_xsl_child->getParentNode->replaceChild($new_PI, $current_xsl_child);
            } 

        } elsif ($current_xsl_child->getTagName =~ /^xsl:output/i) {
 
            # not supported yet, implementation comming up?

        } else {

            # just recurse into sub tree
            $self->_evaluate_contents ($current_xsl_child, $current_xml_node, $current_xml_selection_path);

        }

    } else {

        my $new_value = "";
        print " "x$_indent, "Child: $current_xsl_child\n" if $XSLT::debug;
        my $attr_tmp = $current_xsl_child->getAttributes();
	print " "x$_indent, "Attibs: $attr_tmp\n" if $XSLT::debug;
	for (my $i = 0; $i < $attr_tmp->getLength; $i++) {
	  my $attr_name = $attr_tmp->item($i)->getName;
	  my $attr_value = $attr_tmp->item($i)->getValue;
	  $_ = $attr_value;
	  if ($attr_value ne "") {
	    #test is attribute should be tested
	    if ($attr_value =~ /\{.*\}/) {
	      print " "x$_indent, "Attrib: $attr_name - $attr_value\n" if $XSLT::debug;
	      my ($sec_item, $sec_attr) = $self->parse_select($attr_value);
              my $xml_item = $self->parse_xml_selection ($current_xml_node, $current_xml_selection_path, $sec_item);
  	      print " "x$_indent, "Selected item: $xml_item\n" if $XSLT::debug;
	      if ($sec_attr) {
		$new_value = $xml_item->getAttribute($sec_attr);
	      } else {
		#sort of value-of
        	if ($xml_item->isTextNode) {
        	  $new_value = $xml_item->getNodeValue;
        	} elsif ($xml_item->hasChildNodes) {
        	  $new_value = $xml_item->getFirstChild->getNodeValue;
        	}
	      }
	    } else {
	      $new_value = $attr_value;
	    }
	  }
          print " "x$_indent, "Nieuw: ".$new_value."\n" if $XSLT::debug;	      
          $current_xsl_child->setAttribute($attr_name, $new_value);
	}

        # No xsl command, so just recurse into sub tree
        $self->_evaluate_contents ($current_xsl_child, $current_xml_node, $current_xml_selection_path)

    }

}

sub parse_xml_selection {
  my $self = shift;
  my $current_node = shift;
  my $selection_path = shift;
  my $selection = (shift || "");
  my $content;
  my $child;

  print " "x$_indent, "  selection: \"$selection\"$/" if $XSLT::debug;

  if (($selection =~ /\/\//) || ($selection =~ /\.\./)) {
    print " "x$_indent, "    ** eerste mogelijkheid\n" if $XSLT::debug;
    if ($selection =~ /\{.*\}/i) {
      $content = "$selection_path$selection";
    } else {
      $content = "$selection_path/$selection";
    }
    $content =~ s#\/.*\/\/#\/#;                 # // -> begin from root
    $content =~ s#\/*$##;                       # chop ending /
    $content =~ s#\/.*?\/\.\.##g;               # /abc/.. -> "" get parent of abc

    $child = $XSLT::xml;
  } else {
    print " "x$_indent, "    ** tweede mogelijkheid\n" if $XSLT::debug;
    if ($selection =~ /\{.*\}/i) {
      $content = $selection;
    } elsif ($selection =~ /\./i) {
      $content = "";
    } else {
      $content = "/$selection";
    }
    $content =~ s#\/*$##;                       # chop ending /

    $child = $current_node;
  }

  print " "x$_indent, "    work select: \"$content\"$/" if $XSLT::debug;

  while ($content && $child) {
    if ($content =~ /^\/(\w+)\[(.*?)\]/) {
      $content =~ s/^\/(\w+)\[(.*?)\]//;

      my $child_nodes = $child->getElementsByTagName($1,'');
      $child = "";
      if ($child_nodes->getLength > 0) {
        $child = $child_nodes->item($2)->cloneNode('deep');
      }
    } elsif ($content =~ /^\/(\w+)/) {
      $content =~ s/^\/(\w+)//;

      my $child_nodes = $child->getElementsByTagName($1,'');
      $child = "";
      if ($child_nodes->getLength > 0) {
        $child = $child_nodes->item(0)->cloneNode('deep');
      }
    } elsif ($content =~ /^\@(.+)/) {
      $content =~ s/^\@(.+)//;
      $child = $child->getAttributeNode($1);
    } elsif ($content =~ /^\{(.+)\}/) {
      $content =~ s/^\{(.+)\}//;
      $child = $child->getAttributeNode($1);
    }
  }

  if ($child) {
    if ($child->getNodeType == ATTRIBUTE_NODE) {
      print " "x$_indent, "    attribute: \"", $child->getValue, "\"$/" if $XSLT::debug;
      return ($XSLT::xsl->createTextNode ($child->getValue));
    } else {
      $child = $child->cloneNode('deep');
      $child->setOwnerDocument ($XSLT::xsl);
      $child->normalize();
    }
    if (($XSLT::debug) && ($child->getNodeType != DOCUMENT_NODE)) {
      print " "x$_indent, "    tag: \"", $child->getTagName, "\"$/";
    }
  } else {
    print " "x$_indent, "    no selection", $/ if $XSLT::debug;
  }
  return ($child);
}

sub parse_select {
  my $self = shift;
  my $selection = shift;
  
  print " "x$_indent, "About to parse selection: $selection\n" if $XSLT::debug;

  my $item = "";
  my $attr = "";
  
  $_ = $selection;
  if (m/^\{(.*)\}/) {
    $selection = $1;
    $_ = $selection;
    if (m/(.*)@(.*)/) {
      $item = $1;
      $attr = $2;
    } else {
      $item = $selection;
    }
  }
  
  print " "x$_indent, "  item: $item\n" if $XSLT::debug;  
  print " "x$_indent, "  attr: $attr\n" if $XSLT::debug;  

  return ($item, $attr);
}

sub parse_xsl_select {
  my $self = shift;
  my $selection = (shift || "");
  
  print " "x$_indent, "About to parse xsl:selection: $selection\n" if $XSLT::debug;

  my $item = "";
  my $attr = "";
  my $value = "";
  
  if ($selection =~ /^(.*)\[\@(.*)=(\"|\')(.*)(\"|\')\]/) {
    print " "x$_indent, "  ** Attribute test found\n" if $XSLT::debug;
    $item = $1;
    $attr = $2;
    $value = $4;
  } else {
    $item = $selection;
  }
  
  print " "x$_indent, "  item: $item\n" if $XSLT::debug;  
  print " "x$_indent, "  attr: $attr\n" if $XSLT::debug;  
  print " "x$_indent, "  valu: $value\n" if $XSLT::debug;

  return ($item, $attr, $value);
}

1;
