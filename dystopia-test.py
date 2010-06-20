
import dystopia

db = dystopia.database()
db.open("foo.db", dystopia.CREAT | dystopia.WRITER)
db.put(1234, "hello world")

print db.get(1234), len(db)

db.out(1234)

print db.get(1234), len(db)

