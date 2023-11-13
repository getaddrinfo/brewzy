import genson
import json
import sys

def main():
    if len(sys.argv) == 1:
        print("specify formula or cask")
        return
    

    target = sys.argv[1]

    if target not in {'cask', 'formula'}:
        print("target must be formula or cask")
        return

    with open("out-%s.json" % target, "r") as f:
        data = json.load(f)

    parser = genson.SchemaBuilder()

    for obj in data:
        parser.add_object(obj)

    with open("schema/%s.json" % target, "w") as f:
        f.write(
            parser.to_json(indent=4)
        )

main()