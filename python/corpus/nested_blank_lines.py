class UserService:
    def __init__(self, db):
        self.db = db

    def get_user(self, id):
        return self.db.find(id)

    def delete_user(self, id):
        self.db.remove(id)


def outer():
    x = 1

    def inner():
        return x

    return inner
