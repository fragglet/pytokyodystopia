
import dystopia

db = dystopia.database()
db.open("foo.db", dystopia.CREAT | dystopia.WRITER)
db.put(1234, "hello world")
db.put(1235, "goodbye world")

print db.get(1234), len(db)

print "All objects:"

for id in db:
	print "%i: %s" % (id, db.get(id))

search_results = db.search("world", dystopia.SUBSTR)

print "Searched for 'world', result: %s" % search_results

db.out(1234)

print db.get(1234), len(db)

db.close()

