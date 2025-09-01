# We keep track of all constructed summaries so we can show them
# all at the end of the output.
_all = {}

class Summary:
    SEPARATOR_MAJOR = "=" * 40
    SEPARATOR_MINOR = "-" * 20

    def __init__(self, title):
        self.title = title
        self._status = None
        self._details = []
        _all[title] = self

    def set_status(self, status):
        print(f"---> {self.title}: {status}", flush=True)
        self._status = status

    def add_details(self, details):
        if isinstance(details, list):
            self._details.extend(details)
        else:
            self._details.append(details)

    def show(self):
        print(Summary.SEPARATOR_MAJOR)
        print(f"{self.title}")
        if len(self._details) == 0:
            print(f"{self._status}.")
        else:
            print(f"{self._status}:")
            print(Summary.SEPARATOR_MINOR)
            for line in self._details:
                print(line)
        print(Summary.SEPARATOR_MAJOR, flush=True)

    def all():
        result = []
        for title in sorted(_all.keys()):
            result.append(_all[title])
        return result

    def show_all():
        for summary in Summary.all():
            print("")  # Separate summaries with a newline.
            summary.show()
