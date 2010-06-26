
import dystopia

db = dystopia.IDB()
db.open("foo.db", dystopia.IDB.OCREAT | dystopia.IDB.OWRITER)
db.put(1234, "hello world")
db.put(1235, "goodbye world")

print db.get(1234), len(db)

print "All objects:"

for id in db:
	print "%i: %s" % (id, db.get(id))

search_results = db.search("world", dystopia.IDB.SSUBSTR)

print "Searched for 'world', result: %s" % search_results

db.out(1234)

print db.get(1234), len(db)

db.close()

