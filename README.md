# mmlist2gv
Create mailman lists member hierarchie to graphviz

## Required

* graphviz

## usage

 $ perl mmlist2gv.pl > mmlist.gv
 $ dot -Tpng mmlist.gv > mmlist.png
 
## Configuration

You can modify some Variables in the script. For this open script with a texteditor.

* $DOMAIN search for this domain;
* $MM_PREFIX Mailman directory, default: "/usr/local/mailman";
