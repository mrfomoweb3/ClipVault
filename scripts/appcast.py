#!/usr/bin/env python3
"""Insert/update one release entry in a Sparkle appcast.xml.

Driven by sign_update (which signs reliably from the Keychain). Keeps entries
newest-first and de-dupes by short version string. No third-party deps.

usage:
  appcast.py <appcast_path> <title> <short_version> <build> <min_os> \
             <enclosure_url> <ed_signature> <length_bytes>
"""
import sys, os, datetime, xml.etree.ElementTree as ET

SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE)

def main():
    (appcast, title, short, build, min_os, url, sig, length) = sys.argv[1:9]

    if os.path.exists(appcast):
        tree = ET.parse(appcast)
        root = tree.getroot()
        channel = root.find("channel")
    else:
        root = ET.Element("rss", {"version": "2.0"})
        channel = ET.SubElement(root, "channel")
        ET.SubElement(channel, "title").text = "ClipVault"
        tree = ET.ElementTree(root)

    # Drop any existing item with the same short version (re-release).
    for item in channel.findall("item"):
        sv = item.find(f"{{{SPARKLE}}}shortVersionString")
        if sv is not None and sv.text == short:
            channel.remove(item)

    item = ET.Element("item")
    ET.SubElement(item, "title").text = short
    ET.SubElement(item, "pubDate").text = datetime.datetime.now(
        datetime.timezone.utc
    ).strftime("%a, %d %b %Y %H:%M:%S +0000")
    ET.SubElement(item, f"{{{SPARKLE}}}version").text = build
    ET.SubElement(item, f"{{{SPARKLE}}}shortVersionString").text = short
    ET.SubElement(item, f"{{{SPARKLE}}}minimumSystemVersion").text = min_os
    ET.SubElement(item, "enclosure", {
        "url": url,
        "type": "application/octet-stream",
        "length": length,
        f"{{{SPARKLE}}}edSignature": sig,
    })

    # Newest first: insert right after <title>.
    insert_at = list(channel).index(channel.find("title")) + 1
    channel.insert(insert_at, item)

    ET.indent(tree, space="  ")
    tree.write(appcast, encoding="utf-8", xml_declaration=True)
    print(f"appcast: wrote v{short} (build {build})")

if __name__ == "__main__":
    main()
