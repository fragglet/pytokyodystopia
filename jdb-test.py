
from dystopia import JDB

db = JDB()
db.open("jdb.db", JDB.OCREAT | JDB.OWRITER)
db[1234] = [ "hello", "world" ]
db[1235] = [ "goodbye", "world" ]

print db[1234], len(db)

print "All objects:"

for id in db:
	print "%i: %s" % (id, db[id])

search_results = db.search("orld", JDB.SSUBSTR)

print "Searched for 'orld', result: %s" % search_results

del db[1234]

print db[1234], len(db)

db.close()

