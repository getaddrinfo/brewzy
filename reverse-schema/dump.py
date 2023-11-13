import requests
import json
import sys

def main():
    if len(sys.argv) == 1:
        print("specify either formula or cask")
        return
    
    target = sys.argv[1]

    if target not in {'cask', 'formula'}:
        print("target must be formula or cask")
        return

    print("fetching ...")
    data = requests.get("https://formulae.brew.sh/api/%s.json" % target).json()
    print("dumping ...")

    with open("out/%s.json" % target, "w") as f:
        json.dump(data, f)
    
    print("done")

main()