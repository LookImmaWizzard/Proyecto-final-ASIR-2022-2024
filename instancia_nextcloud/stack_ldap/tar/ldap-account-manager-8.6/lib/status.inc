<?php
/*

  This code is part of LDAP Account Manager (http://www.ldap-account-manager.org/)
  Copyright (C) 2003 - 2006  Michael Duergner
                2011 - 2022  Roland Gruber

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/**
 * LDAP Account Manager status messages.
 *
 * @author Michael Duergner
 * @package lib
 */

/**
 * This function prints a short status message. It can be used to print INFO,
 * WARN and ERROR messages at the moment.
 *
 * The headline and text may be formatted with special tags:
 * <br>
 * <br><b>{bold}, {endbold}:</b> All text between these tags is printed bold.
 * <br><b>{color=#123456}, {endcolor}:</b> All text between these tags is printed in the given color.
 * <br><b>{link=http://nodomain.org}, {endlink}:</b> A link with the given target is created. The link text is the text between the tags.
 *
 * @param string $MessageTyp The type of the message to be printed. It must be one of
 * the following types: 'INFO', 'WARN' or 'ERROR'.
 * <br> Every other type will lead to an error message indicating an invalid message type.
 * @param string $MessageHeadline The headline of the status message.
 * <br> It may be formatted with special color/link/bold tags.
 * @param string $MessageText The text of the status message.
 * <br> It may be formatted with special color/link/bold tags. This parameter is optional.
 * @param array $MessageVariables The variables that are used to replace the spacers (%s) in the
 * submitted text. This parameter is optional.
 * @param boolean $returnOutput if set to true this function will return the generated HTML code instead of printing it directly (default: false)
 * @return String HTML code if $returnOutput is set to true, otherwise null
 */
function StatusMessage($MessageTyp, $MessageHeadline, $MessageText = '', $MessageVariables = array(), $returnOutput = false) {
	/* Setting CSS-StyleSheet class depending on the $MessageTyp and rewriting $MessageTyp with a readable string. */
	if ($MessageTyp == "INFO") {
		$class = "class=\"statusInfo lam-status-message\"";
	}
	elseif ($MessageTyp == "WARN") {
		$class = "class=\"statusWarn lam-status-message\"";
	}
	elseif ($MessageTyp == "ERROR") {
		$class = "class=\"statusError lam-status-message\"";
	}
	/* Set output-message, when none or false $MessageTyp is submitted. */
	else {
		$class = "class=\"statusError lam-status-message\"";
		$MessageHeadline = "Invalid/Missing Message type";
		$MessageText = "Please report this error to the Bug-Tracker at {link=http://www.ldap-account-manager.org/}LDAP Account Manager Development Team{endlink}. Thank you.";
	}

	$MessageHeadline = parseMessageString($MessageHeadline);
	$MessageText = parseMessageString($MessageText);

	$MessageHeadline = "<div class=\"statusTitle\">" . $MessageHeadline . "</div>"; // Format $MessageHeadline
	if ($MessageText != '') {
		$MessageText = "<p class=\"statusText\">" . $MessageText . "</p>"; // Format $MessageText
	}
	$format = "<div " . $class . ">\n<table>\n<tr>\n<td>" . $MessageHeadline . $MessageText . "</td>\n</tr>\n</table>\n</div>\n";
	$output = '';
	if (is_array($MessageVariables)) {
		if (sizeof($MessageVariables) > 0) {
			array_unshift($MessageVariables, $format);
			$output = call_user_func_array('sprintf',$MessageVariables);
		}
		else {
			$output = $format;
		}
	}
	elseif ($MessageVariables !== null) {
		$output = sprintf($format, $MessageVariables);
	}
	else {
		$output = $format;
	}
	if ($returnOutput) {
		return $output;
	}
	else {
		echo $output;
	}
	return null;
}

/**
 * Use the three replace functions on the submitted Text.
 *
 * @access private
 *
 * @param string $MessageString The text that is used to search for replaceable strings.
 *
 * @return string The processed text.
 */
function parseMessageString($MessageString) {
	return linkText(colorText(boldText($MessageString)));
}

/**
 * Replace {bold} and {endbold} with <b> and </b> HTML-Tags.
  *
 * @access private
 *
 * @param string $text The text that is used to search for {bold} and {endbold} tags.
 *
 * @return string The submitted text with {bold} and {endbold} replaced with
 * the appropriate HTML tags <b> and </b>
 */
function boldText($text) {
	if ($text === null) {
		return null;
	}
	$pattern = "/\\{bold\\}([^{]*)\\{endbold\\}/"; // Regular expression matching {bold}[Text]{endbold}
	$replace = "<b class=\"status\">\\1</b>"; // Replace pattern
	return preg_replace($pattern, $replace, $text);
}

/**
 * Replace {color=#[HEX-Value]} or {color=[HEX-Value]} and {endcolor} with <font color="#[HEX-Value]"> and </font> HTML-Tags.
 *
 * @access private
 *
 * @param string $text The text that is used to search for {color} and {endcolor} tags.
 *
 * @return string Input string with HTML-formatted color tags
 */
function colorText($text) {
	if ($text === null) {
		return null;
	}
	$pattern = "/\\{color=#?([0-9,a-f,A-F]{6})\\}([^{]*)\\{endcolor\\}/"; // Regular expression matching {color=#[HEX-Value]}[Text]{endcolor} or {color=[HEX-Value]}[Text]{endcolor}
	$replace = "<font color=\"#\\1\">\\2</font>"; // Replace pattern
	return preg_replace($pattern,$replace,$text);
}

/**
 * Replace {link=[Link-Target]} and {endlink} with <a href="[Link-Target]" target="_blank"> and </a> HTML-Tags.
 *
 * @access private
 *
 * @param string $text The text that is used to search for {link} and {endlink} tags.
 *
 * @return string Input string with HTML-formatted link tags
 */
function linkText($text) {
	if ($text === null) {
		return null;
	}
	$pattern = "/\\{link=([^}]*)\\}([^{]*)\\{endlink\\}/"; // Regular expression matching {link=[Link-Target]}[Text]{endlink}
	$replace = "<a href=\"\\1\" target=\"_blank\">\\2</a>"; //Replace pattern
	return preg_replace($pattern,$replace,$text);
}
