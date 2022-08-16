import * as React from "react"
import { Link, graphql, withPrefix } from "gatsby"

import Burrito from "../components/burrito"
import Seo from "../components/seo"
import Tags from "../components/tags"

const TagTemplate = ({ data, location, pageContext }) => {
  const edges = data.allMarkdownRemark.edges
  const siteTitle = data.site.siteMetadata?.title
  const { tag } = pageContext
  return (
    <Burrito location={location} title={siteTitle}>
      <Seo title={tag} description={data.allMarkdownRemark.excerpt} />
      <div className="tag-exercises">
        <div className="tag">
          <p>{tag}</p>
        </div>
        <div className="tag-description">
          <p>{descriptions[tag]}</p>
        </div>
        <ol style={{ listStyle: `none` }}>
          {edges.map(edge => {
            const node = edge.node
            return (
              <li key={node.fields.slug} className="tag-exercise">
                <h2>
                  <Link to={withPrefix(node.fields.slug)} itemProp="url">
                    <span itemProp="headline">{node.frontmatter.title}</span>
                  </Link>
                </h2>
                <div>
                  {node.frontmatter.tags && (
                    <Tags
                      tags={node.frontmatter.tags}
                      tagSlugs={node.fields.tagSlugs}
                    />
                  )}
                </div>
              </li>
            )
          })}
        </ol>
      </div>
    </Burrito>
  )
}

export default TagTemplate

export const pageQuery = graphql`
  query TagBySlug($tag: String!) {
    site {
      siteMetadata {
        title
      }
    }
    allMarkdownRemark(filter: { frontmatter: { tags: { eq: $tag } } }) {
      edges {
        node {
          fields {
            slug
            tagSlugs
          }
          frontmatter {
            title
            tags
          }
        }
      }
    }
  }
`

const descriptions = {
  pull:
    "Pull from your visual library: practice drawing from memory and imagination",
  push: "Push into your visual library: practice drawing from reference",
}
