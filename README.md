FGases.xqueries
===============

There are two entry points:

 * fgases-2015.xquery - FGases dataflow (Main module)
 * [broken] fgases-envelope.xquery - FGases dataflow envelope level check(Main module)

Run:

    java -cp lib/saxon9-xqj.jar:lib/saxon9he.jar net.sf.saxon.Query -qversion:1.0 fgases-2015.xquery source_url=fgases-test.xml
