
import dystopia

db = dystopia.IDB()
db.open("foo.db", dystopia.IDB.OCREAT | dystopia.IDB.OWRITER)
db[1234] = "hello world"
db[1235] = "goodbye world"

print db[1234], len(db)

print "All objects:"

for id in db:
	print "%i: %s" % (id, db[id])

search_results = db.search("world", dystopia.IDB.SSUBSTR)

print "Searched for 'world', result: %s" % search_results

del db[1234]

print db[1234], len(db)

db.close()

