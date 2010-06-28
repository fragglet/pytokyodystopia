
from dystopia import IDB

db = IDB()
db.open("idb-test.db", IDB.OCREAT | IDB.OWRITER)
db[1234] = "hello world"
db[1235] = "goodbye world"

print db[1234], len(db)

print "All objects:"

for id in db:
	print "%i: %s" % (id, db[id])

search_results = db.search("world", IDB.SSUBSTR)

print "Searched for 'world', result: %s" % search_results

del db[1234]

print db[1234], len(db)

db.close()

